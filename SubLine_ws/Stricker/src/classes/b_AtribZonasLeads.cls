public class b_AtribZonasLeads implements Database.Batchable<sObject>{
    
    public Map<String, Map<String, Atribuicao_de_zonas__c>> zonas;
    public Set<Id> leadsId;
    public Set<String> countries;
    
    //Chamar este construtor para criar scope com base nas leads alteradas
    public b_AtribZonasLeads(Set<Id> leadsId, boolean exec){
        this.leadsId = leadsId;
        zonas = new Map<String, Map<String, Atribuicao_de_zonas__c>>();
        countries = new Set<String>();
        if(leadsId.size() > 49000 || Test.isRunningTest()){//previne limites de select pre scope e vai buscar todas as zonas
            for(Atribuicao_de_zonas__c az : [SELECT Id, OwnerId, Name, Pais__c, Zona__c, Codigo_postal_Minimo__c, Codigo_postal_Maximo__c, Mercado__c, Escalao_Hidea__c, Limite_operacional_da_divida__c, 
                                             Limite_operacional_da_divida_titulada__c, Numero_de_dias_de_Vencimento__c, Plafond_Comercial__c, Plafond_Operacional__c, Plafond_CyC__c, Tabela_de_precos__c,
                                             Area__c, Comercial__c, Assistente__c, Director__c, Idioma_do_Cliente__c, Idioma_para_faturacao__c,Limite_de_credito_comercial__c
                                             FROM Atribuicao_de_zonas__c]){
                if(!zonas.containsKey(az.Pais__c)){
                    zonas.put(az.Pais__c, new Map<String, Atribuicao_de_zonas__c>());
                }
                zonas.get(az.Pais__c).put(az.Codigo_postal_Minimo__c + '-' + az.Codigo_postal_Maximo__c, az);
            }
        }else{
            for(Lead l :[Select CountryCode From Lead Where Id In :leadsId]){//vai buscar as leads que foram actualizadas para serem corrigidas
                countries.add(l.CountryCode);
            }
            buildZonasByCode();
        }
        //execute
        if(exec) Database.executeBatch(this);//executa-se a ele proprio
    }
	
    //Chamar este construtor para criar scope com base nos paises
    public b_AtribZonasLeads(Set<String> countries, boolean exec){
        this.leadsId = new Set<Id>();
        zonas = new Map<String, Map<String, Atribuicao_de_zonas__c>>();
        this.countries = countries;
        buildZonasByCode();
        if(exec)
            Database.executeBatch(this);
    }
    
    //constroi mapa de zonas pelos codigos presentes no set countries
    public void buildZonasByCode(){
        for(Atribuicao_de_zonas__c az : [SELECT Id, OwnerId, Name, Pais__c, Zona__c, Codigo_postal_Minimo__c, Codigo_postal_Maximo__c, Mercado__c, Escalao_Hidea__c, Limite_operacional_da_divida__c, 
                                         Limite_operacional_da_divida_titulada__c, Numero_de_dias_de_Vencimento__c, Plafond_Comercial__c, Plafond_Operacional__c, Plafond_CyC__c, Tabela_de_precos__c,
                                         Area__c, Comercial__c, Assistente__c, Director__c, Idioma_do_Cliente__c, Idioma_para_faturacao__c,Limite_de_credito_comercial__c
                                         FROM Atribuicao_de_zonas__c Where Pais__c In :countries]){
            if(!zonas.containsKey(az.Pais__c)){
                zonas.put(az.Pais__c, new Map<String, Atribuicao_de_zonas__c>());
            }
            zonas.get(az.Pais__c).put(az.Codigo_postal_Minimo__c + '-' + az.Codigo_postal_Maximo__c, az);
        }
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        if(!leadsId.isEmpty()){//construir por leads
            return Database.getQueryLocator([Select id, CountryCode, PostalCode From Lead Where Id In :leadsId And isConverted = false]);
        }else if(!countries.isEmpty()){//construir por zonas
            return Database.getQueryLocator([Select id, CountryCode, PostalCode From Lead Where CountryCode In :zonas.keySet() And isConverted = false]);
        }
		return null;
    }
    
    public void execute(Database.BatchableContext BC, List<Lead> scope){
        if([Select Id, Ativo__c From Atribuicao_zona_config__mdt Where DeveloperName = 'Atrib_Leads'].Ativo__c || Test.isRunningTest()){
            checkRecursive.runFalse();
            List<Lead> updateLeads = new List<Lead>();
            
            Atribuicao_de_zonas__c restoMundo;
            try{
                restoMundo = [SELECT Id, OwnerId, Name, Pais__c, Zona__c, Codigo_postal_Minimo__c, Codigo_postal_Maximo__c, Mercado__c, Area__c, 
                              Comercial__c, Assistente__c, Assistente_comercial_aux__c, Director__c,Comercial__r.Name,Comercial__r.Codigo_de_utilizador__c,
                              Assistente__r.Codigo_de_utilizador__c,Director__r.Name,Director__r.Codigo_de_utilizador__c
                              FROM Atribuicao_de_zonas__c Where Pais__c = '' Limit 1];
            }catch(Exception ex){}
            
            for(Lead l : scope){
                if(zonas.containsKey(l.CountryCode)){//Pais existe nas zonas
                    if(zonas.get(l.CountryCode).size() == 1){//é apenas 1 pais
                        String firstKey = l.CountryCode;
                        String secondKey;
                        for (string setElement : zonas.get(l.CountryCode).keySet()) {
                            secondKey = setElement;
                            break;
                        }
                        mapLeadFields(l, zonas.get(firstKey).get(secondKey));//Mapear do primeiro registo
                        updateLeads.add(l);
                    }else{
                        for(String secondKey : zonas.get(l.CountryCode).keySet()){
                            if(secondKey.contains('-')){//garante que existe '-' na chave
                                String[] splitted = secondKey.split('-');
                                String minRange = splitted[0].replaceAll(',', '');
                                String maxRange = splitted.size() > 1 ? splitted[1].replaceAll(',', '') : splitted[0].replaceAll(',', '');
                                if(l.PostalCode == minRange || l.PostalCode == maxRange || (l.PostalCode.startsWith(minRange) || l.PostalCode.startsWith(maxRange))){
                                    //verifica logo o min/max antes de ter de fazer conversao para numericos
                                    //serve tambem para ver codigos que nao sao completamente numericos, i.e: contem letras.
                                    mapLeadFields(l, zonas.get(l.CountryCode).get(secondKey));
                                    updateLeads.add(l);
                                }else{
                                    if(minRange.isNumeric() && maxRange.isNumeric()){//verifica se é numerico
                                        //converte para numericos para comparacao de range
                                        Decimal min = Decimal.valueOf(minRange);
                                        Decimal max = Decimal.valueOf(maxRange);
                                        String code = (l.PostalCode != null && l.PostalCode.contains('-')) ? l.PostalCode.split('-')[0] : l.PostalCode;
                                        Decimal nCode = (code != null && code.isNumeric()) ? Decimal.valueOf(code) : null;
                                        //se nao for numerico nesta altura e porque nao existe
                                        if(nCode != null && nCode >= min && nCode <= max){//se encontrar range certo
                                            mapLeadFields(l, zonas.get(l.CountryCode).get(secondKey));
                                            updateLeads.add(l);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }else if(restoMundo != null){
                    mapLeadFields(l, restoMundo);
                    updateLeads.add(l);
                }
            }
            if(!updateLeads.isEmpty()) update updateLeads;   
        }
    }
    
    public void finish(Database.BatchableContext BC){}
    
    public void mapLeadFields(Lead l, Atribuicao_de_zonas__c atb){
        l.OwnerId = atb.Assistente__c;
        l.Mercado__c = atb.Mercado__c;
        l.Zona__c = atb.Zona__c;
        l.Area__c = atb.Area__c;
        //adicionados a 2018-02-07 para que exista esta informação no momento de conversão da lead para conta, e criação de cliente no PHC
        l.Comercial__c = atb.Comercial__c; //REMOVIDO 2018-05-22
        l.Diretor_Comercial__c = atb.Director__c;
        //adicionados a 2018-05-22 com a nova atribuição de zonas
        l.Atribuicao_de_zonas__c = atb.Id;
        l.Escalao_Hidea__c = atb.Escalao_Hidea__c;
        l.Limite_de_credito_comercial__c = atb.Limite_de_credito_comercial__c;
        l.Limite_operacional_de_divida__c = atb.Limite_operacional_da_divida__c;
        l.Limite_operacional_da_divida_titulada__c = atb.Limite_operacional_da_divida_titulada__c;
        l.Numero_de_dias_de_vencimento__c = atb.Numero_de_dias_de_Vencimento__c;
        l.Plafond_comercial__c = atb.Plafond_Comercial__c;
        l.Plafond_operacional__c = atb.Plafond_Operacional__c;
        l.Plafond_CyC__c = atb.Plafond_CyC__c;
        l.Tabela_de_precos__c = atb.Tabela_de_precos__c;
        l.Idioma_de_comunicacao__c = atb.Idioma_do_Cliente__c;
        l.Idioma_para_faturacao__c = atb.Idioma_para_faturacao__c;
    }
}