trigger t_Account on Account (before insert, after insert,before update, after update) {
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            if(checkRecursive.runAccount){
                checkRecursive.runAccount = false;
                
                Set<ID> accountIdsUpdate = new Set<Id>();
                Set<Id> accsToUpdateAtrib = new Set<Id>();
                List<Schema.FieldSetMember> queryFields = SObjectType.Account.FieldSets.Integration_Fields.getFields();
                List<Schema.FieldSetMember> queryFields2 = SObjectType.Account.FieldSets.CamposAtribuicao.getFields();
                for(Id accId : Trigger.newMap.keySet()){

                    Boolean isChange = false;
                    
                    
                    sObject newAcc = (sObject)Trigger.newMap.get(accId);
                    sObject oldAcc = (sObject)Trigger.oldMap.get(accId);
                    for(Schema.FieldSetMember field : queryFields){
                        if(newAcc.get(field.getFieldPath()) != oldAcc.get(field.getFieldPath())){
                            isChange = true;
                            break;
                        }
                    }
                    
                    if(isChange){
                        accountIdsUpdate.add(accId);
                    }
                    
                    isChange = false;
                    
                    newAcc = (sObject)Trigger.newMap.get(accId);
                    oldAcc = (sObject)Trigger.oldMap.get(accId);
                    for(Schema.FieldSetMember field : queryFields2){
                        if(newAcc.get(field.getFieldPath()) != oldAcc.get(field.getFieldPath()) && !((boolean) newAcc.get('Atribuicao_zonas_manual__c'))){
                            isChange = true;
                            break;
                        }
                    }
                    
                    if(isChange){
                        accsToUpdateAtrib.add(accId);
                    }
                }
                if(accountIdsUpdate.size() > 0 && !System.isFuture() && !System.isBatch()){
                    sh_UpdateClient.job(accountIdsUpdate);
                }
                if(!accsToUpdateAtrib.isEmpty()){
                    b_AtribZonasAccounts atb = new b_AtribZonasAccounts(accsToUpdateAtrib, !System.isFuture());
                    if(System.isFuture() && !System.isBatch())atb.execute(null, [Select id, BillingCountryCode, BillingPostalCode From Account Where Id In :accsToUpdateAtrib]);
                }
            }
        }else if(Trigger.isInsert){
            if(checkRecursive.runAccount){
                b_AtribZonasAccounts atb = new b_AtribZonasAccounts(Trigger.newMap.keySet(), !System.isFuture());
                if(System.isFuture() && !System.isBatch())atb.execute(null, [Select id, BillingCountryCode, BillingPostalCode From Account Where Id In :Trigger.new]);
            }
        }
    }else if(Trigger.isBefore){
        if(Trigger.isInsert){
            
            Map<String, List<Objectivo_de_faturacao__c>> objectivos = new Map<String, List<Objectivo_de_faturacao__c>>();
            
            for(Objectivo_de_faturacao__c obj : [Select Id, Pais__c, Mercado__c From Objectivo_de_faturacao__c Where Ano__c = :System.today().year()]){
                if(!objectivos.containsKey(obj.Pais__c)){
                    objectivos.put(obj.Pais__c, new List<Objectivo_de_faturacao__c>());
                }
                objectivos.get(obj.Pais__c).add(obj);
            }
                
            for(Account acc : Trigger.new){
                if(objectivos.containsKey(acc.Prefixo_pais_de_contribuinte__c)){
                    if(objectivos.get(acc.Prefixo_pais_de_contribuinte__c).size() > 1){
                        for(Objectivo_de_faturacao__c objectivo : objectivos.get(acc.Prefixo_pais_de_contribuinte__c)){
                            if(acc.Mercado__c == objectivo.Mercado__c){
                                acc.Objectivo_de_faturacao__c = objectivo.Id;
                            }
                        }
                    }else{
                        acc.Objectivo_de_faturacao__c = objectivos.get(acc.Prefixo_pais_de_contribuinte__c).get(0).Id;
                    }
                    
                }else if(objectivos.containsKey(null)){
                    acc.Objectivo_de_faturacao__c = objectivos.get(null).get(0).Id;
                }
                
            }
        }else if(Trigger.isUpdate){
            Set<Id> userIds = new Set<Id>();
            for(Account acc : Trigger.new){
                userIds.add(acc.Assistente_comercial__c);
                userIds.add(acc.Diretor_comerial__c);
                userIds.add(acc.OwnerId);
            }
            Map<Id,User> usersMap = new Map<Id, User>([Select id, Name, Codigo_de_utilizador__c from User Where Id In :userIds]);
            
            for(Account acc : Trigger.new){
                //atualizar campos de owner, assistente e diretor comercial
                if(usersMap.containsKey(acc.Assistente_comercial__c) && usersMap.containsKey(acc.Diretor_comerial__c) && usersMap.containsKey(acc.OwnerId)){
                    acc.Owner_aux__c = usersMap.get(acc.OwnerId).Name;
                    acc.Codigo_Owner_aux__c = usersMap.get(acc.OwnerId).Codigo_de_utilizador__c;
                    acc.Assistente_comercial_aux__c = usersMap.get(acc.Assistente_comercial__c).Name;
                    acc.Codigo_Assistente_Aux__c = usersMap.get(acc.Assistente_comercial__c).Codigo_de_utilizador__c;
                    acc.Diretor_aux__c = usersMap.get(acc.Diretor_comerial__c).Name;
                    acc.Codigo_Diretor_Aux__c = usersMap.get(acc.Diretor_comerial__c).Codigo_de_utilizador__c;
                }
                
                //actualização de campos para efeitos de visit reports com a data de atualização de cada campo
                sObject newAcc = (sObject)Trigger.newMap.get(acc.Id);
                sObject oldAcc = (sObject)Trigger.oldMap.get(acc.Id);
                for(Schema.FieldSetMember field : SObjectType.Account.FieldSets.Relatorios_de_Visita.getFields()){
                    if(newAcc.get(field.getFieldPath()) != oldAcc.get(field.getFieldPath())){
                        try{
                            acc.put('Alt_'+field.getFieldPath(), System.today());
                        }catch(Exception ex){
                            system.debug(ex.getMessage());
                            system.debug('O marco é nabo e devia de se manter pelo código: ' + field.getFieldPath());
                        }
                    }
                }
                
                //acompanhar moeda da ficha de cliente com moeda correspondente à tabela de preços
               if(ProductManager.mapISOCodes.containsKey(acc.Tabela_de_precos__c)) acc.CurrencyIsoCode = ProductManager.mapISOCodes.get(acc.Tabela_de_precos__c);
            }
        }
    }
}