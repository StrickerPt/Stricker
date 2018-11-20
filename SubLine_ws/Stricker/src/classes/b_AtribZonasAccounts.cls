public class b_AtribZonasAccounts implements Database.Batchable<sObject>,Database.Stateful, Database.AllowsCallouts{
    
    
    public Map<String, Map<String, Atribuicao_de_zonas__c>> zonas;
    public Set<Id> accIds;
    public Set<String> countries;
    
    public static final Integer MAX_BATCH = 20;
    
    //Chamar este construtor para criar scope com base nas contas alteradas
    public b_AtribZonasAccounts(Set<Id> accIds, boolean exec){
        this.accIds = accIds;
        zonas = new Map<String, Map<String, Atribuicao_de_zonas__c>>();
        countries = new Set<String>();
        if(accIds.size() > 49000 || Test.isRunningTest()){//previne limites de select pre scope e vai buscar todas as zonas
            for(Atribuicao_de_zonas__c az : [SELECT Id, OwnerId, Name, Pais__c, Zona__c, Codigo_postal_Minimo__c, Codigo_postal_Maximo__c, Mercado__c, Area__c, 
                                             Comercial__c, Assistente__c, Assistente__r.Name, Assistente_comercial_aux__c, Director__c,Comercial__r.Name,Comercial__r.Codigo_de_utilizador__c,
                                             Assistente__r.Codigo_de_utilizador__c,Director__r.Name,Director__r.Codigo_de_utilizador__c
                                             FROM Atribuicao_de_zonas__c]){
                                                 String key = az.Pais__c != null ? az.Pais__c : '';
                                                 if(!zonas.containsKey(key)){
                                                     zonas.put(key, new Map<String, Atribuicao_de_zonas__c>());
                                                 }
                                                 zonas.get(key).put(az.Codigo_postal_Minimo__c + '-' + az.Codigo_postal_Maximo__c, az);
                                             }
        }else{
            for(Account acc :[Select BillingCountryCode From Account Where Id In :accIds]){//vai buscar as contas que foram actualizadas para serem corrigidas
                countries.add(acc.BillingCountryCode);
            }
            buildZonasByCode();
        }
        //execute
        if(exec) Database.executeBatch(this, MAX_BATCH);//executa-se a ele proprio
    }
    
    //Chamar este construtor para criar scope com base nos paises
    public b_AtribZonasAccounts(Set<String> countries, boolean exec){
        this.accIds = new Set<Id>();
        zonas = new Map<String, Map<String, Atribuicao_de_zonas__c>>();
        this.countries = countries;
        buildZonasByCode();
        if(exec) Database.executeBatch(this, MAX_BATCH);
    }
    
    //constroi mapa de zonas pelos codigos presentes no set countries
    public void buildZonasByCode(){
        for(Atribuicao_de_zonas__c az : [SELECT Id, OwnerId, Name, Pais__c, Zona__c, Codigo_postal_Minimo__c, Codigo_postal_Maximo__c, Mercado__c, Area__c, 
                                         Comercial__c, Assistente__c, Assistente_comercial_aux__c, Director__c,Comercial__r.Name,Comercial__r.Codigo_de_utilizador__c,
                                         Assistente__r.Codigo_de_utilizador__c, Assistente__r.Name,Director__r.Name,Director__r.Codigo_de_utilizador__c
                                         FROM Atribuicao_de_zonas__c Where Pais__c In :countries]){
                                             String key = az.Pais__c != null ? az.Pais__c : '';
                                             if(!zonas.containsKey(key)){
                                                 zonas.put(key, new Map<String, Atribuicao_de_zonas__c>());
                                             }
                                             zonas.get(key).put(az.Codigo_postal_Minimo__c + '-' + az.Codigo_postal_Maximo__c, az);
                                         }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        if(!accIds.isEmpty()){//construir por contas
            String query = 'SELECT '+Integrator.queryBuilder('Account') + ',Assistente_comercial__r.Name,Diretor_comerial__r.Name,Owner.Name,Owner.Codigo_de_utilizador__c,CurrencyIsoCode';
            query += ' FROM Account Where Atribuicao_zonas_manual__c = false And Id In :accIds';
            system.debug(query);
            return Database.getQueryLocator(query);
        }else if(!countries.isEmpty()){//construir por zonas
            String query = 'SELECT '+Integrator.queryBuilder('Account') + ',Assistente_comercial__r.Name,Diretor_comerial__r.Name,Owner.Name,Owner.Codigo_de_utilizador__c,CurrencyIsoCode';
            query += ' FROM Account Where Atribuicao_zonas_manual__c = false And BillingCountryCode In ';
            String aux = '(';
            boolean isFirst = true;
            for(String s : zonas.keySet()){
                if(isFirst){
                    isFirst = false;
                }else{
                    aux += ',';
                }
                aux += '\'' + s + '\'';
            }
            aux += ')';
            
            query += aux;
            system.debug(query);
            return Database.getQueryLocator(query);
        }
        return null;
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope){
        if([Select Id, Ativo__c From Atribuicao_zona_config__mdt Where DeveloperName = 'Atrib_Contas'].Ativo__c || Test.isRunningTest()){
            checkRecursive.runFalse();
            Atribuicao_de_zonas__c restoMundo;
            try{
                restoMundo = [SELECT Id, OwnerId, Name, Pais__c, Zona__c, Codigo_postal_Minimo__c, Codigo_postal_Maximo__c, Mercado__c, Area__c, 
                              Comercial__c, Assistente__c, Assistente_comercial_aux__c, Director__c,Comercial__r.Name,Comercial__r.Codigo_de_utilizador__c,
                              Assistente__r.Codigo_de_utilizador__c,Director__r.Name,Director__r.Codigo_de_utilizador__c
                              FROM Atribuicao_de_zonas__c Where Pais__c = '' Limit 1];
            }catch(Exception ex){}
            List<Account> updateAccounts = new List<Account>();
            
            for(Account acc : scope){
                string key = acc.BillingCountryCode != null ? acc.BillingCountryCode : '';
                if(zonas.containsKey(key)){//Pais existe nas zonas
                    //system.debug(LoggingLevel.INFO, zonas);
                    if(zonas.get(key).size() == 1){//é apenas 1 pais
                        String firstKey = key;
                        String secondKey;
                        for (string setElement : zonas.get(key).keySet()) {
                            secondKey = setElement;
                            break;
                        }
                        mapAccountFields(acc, zonas.get(firstKey).get(secondKey));//Mapear do primeiro registo
                        updateAccounts.add(acc);
                    }else{
                        for(String secondKey : zonas.get(key).keySet()){
                            if(secondKey.contains('-')){//garante que existe '-' na chave
                                String[] splitted = secondKey.split('-');
                                String minRange = splitted[0].replaceAll(',', '');
                                String maxRange = splitted.size() > 1 ? splitted[1].replaceAll(',', '') : splitted[0].replaceAll(',', '');
                                if(acc.BillingPostalCode == minRange || acc.BillingPostalCode == maxRange || (acc.BillingPostalCode.startsWith(minRange) || acc.BillingPostalCode.startsWith(maxRange))){
                                    //verifica logo o min/max antes de ter de fazer conversao para numericos
                                    //serve tambem para ver codigos que nao sao completamente numericos, i.e: contem letras.
                                    mapAccountFields(acc, zonas.get(key).get(secondKey));
                                    updateAccounts.add(acc);
                                }else{
                                    //system.debug(minRange + ' ' + maxRange);
                                    //system.debug(minRange.isNumeric() + ' ' + maxRange.isNumeric());
                                    if(minRange.isNumeric() && maxRange.isNumeric()){//verifica se é numerico
                                        //converte para numericos para comparacao de range
                                        Decimal min = Decimal.valueOf(minRange);
                                        Decimal max = Decimal.valueOf(maxRange);
                                        String code = (acc.BillingPostalCode != null && acc.BillingPostalCode.contains('-')) ? acc.BillingPostalCode.split('-')[0] : acc.BillingPostalCode;
                                        Decimal nCode = (code != null && code.isNumeric()) ? Decimal.valueOf(code) : null;
                                        //se nao for numerico nesta altura e porque nao existe
                                        if(nCode != null && nCode >= min && nCode <= max){//se encontrar range certo
                                            system.debug(key);
                                            system.debug(zonas.get(key));
                                            mapAccountFields(acc, zonas.get(key).get(secondKey));
                                            updateAccounts.add(acc);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }else if(restoMundo != null){
                    mapAccountFields(acc, restoMundo);
                    updateAccounts.add(acc);
                }
            }
            system.debug(updateAccounts);
            
            if(!Trigger.isExecuting) sh_UpdateClient.doRequests(updateAccounts);
            if(!updateAccounts.isempty()) update updateAccounts;
            if(errorMessages != '') UtilClaims.sendEmailFailure('Falha update de cliente', errorMessages);
            
        }
    }
    public static String errorMessages = '';
    public void finish(Database.BatchableContext BC){}
    
    public void mapAccountFields(Account acc, Atribuicao_de_zonas__c atb){
        acc.OwnerId = atb.Comercial__c;
        acc.Owner_aux__c = atb.Comercial__r.Name;
        acc.Codigo_Owner_aux__c = atb.Comercial__r.Codigo_de_utilizador__c;
        acc.Mercado__c = atb.Mercado__c;
        acc.Area__c = atb.Area__c;
        acc.Assistente_comercial__c = atb.Assistente__c;
        acc.Assistente_comercial_aux__c = atb.Assistente__r.Name;
        acc.Codigo_Assistente_Aux__c = atb.Assistente__r.Codigo_de_utilizador__c;
        acc.Diretor_comerial__c = atb.Director__c;
        acc.Diretor_aux__c = atb.Director__r.Name;
        acc.Codigo_Diretor_Aux__c = atb.Director__r.Codigo_de_utilizador__c;
        acc.Atribuicao_de_zonas__c = atb.Id;
        acc.Zona__c = atb.Zona__c;
    }
    
}