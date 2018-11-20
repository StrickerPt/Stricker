trigger t_Morada on Morada_de_entrega__c  (before insert, after insert, after update, before delete) {
    if(checkRecursive.runMoradaCliente){
        if(Trigger.isAfter){
            checkRecursive.runMoradaCliente = false;
            if(Trigger.isUpdate){
                List<Schema.FieldSetMember> queryFields = SObjectType.Morada_de_entrega__c.FieldSets.Integration_Fields.getFields(); 
                Set<Id> moradaIDs = new Set<Id>();
                for(Id moradaID : Trigger.newMap.keySet()){
                    
                    Boolean isChange = false;
                    sObject newCon = (sObject)Trigger.newMap.get(moradaID);
                    sObject oldCon = (sObject)Trigger.oldMap.get(moradaID);
                    for(Schema.FieldSetMember field : queryFields){
                        if(newCon.get(field.getFieldPath()) != oldCon.get(field.getFieldPath())){
                            isChange = true;
                            break;
                        }
                    }
                    
                    if(isChange){
                        moradaIDs.add(moradaID);
                    }
                    
                }
                
                //@toDo webservice call
                if(!moradaIDs.isEmpty()){
                    IntegratorMoradas.moradaClienteUpsert(moradaIDs);
                    
                    Database.executeBatch(new b_UpdateLinesAddress(moradaIDs), 1);
                }
                
            }else if(Trigger.isInsert){
                if(!System.isFuture() && !System.isBatch() && !Test.isRunningTest())IntegratorMoradas.moradaClienteUpsert(Trigger.newMap.keySet());
            }
        }else{
            if(Trigger.isInsert){
                Set<Id> accIds = new Set<Id>();
                for(Morada_de_entrega__c m : Trigger.new){
                    if(m.Conta__c != null){
                        accIds.add(m.Conta__c);
                    }
                }
                Map<ID, Account> accounts = new Map<Id, Account>([Select id, Auxiliar_morada_de_entrega__c,(select id, MSEQ__c from Moradas_de_entrega__r Order by MSEQ__C Desc Limit 1) From Account Where Id In :accIds]);
                for(Morada_de_entrega__c m : Trigger.new){
                    if(m.Conta__c != null && m.Stamp__c == null && m.MSEQ__c == null){
                        m.MSEQ__c = accounts.get(m.Conta__c).Moradas_de_entrega__r.isEmpty() ? 0 : accounts.get(m.Conta__c).Moradas_de_entrega__r.get(0).MSEQ__c + 1;
                    }
                }
                if(!accounts.isEmpty()) update accounts.values();
            }else if(Trigger.isDelete){
                List<IntegratorMoradas.DeleteMoradaCliente> lista = new List<IntegratorMoradas.DeleteMoradaCliente>();
                for(Morada_de_entrega__c c : Trigger.old){
                    IntegratorMoradas.DeleteMoradaCliente delCont = new IntegratorMoradas.DeleteMoradaCliente(c.Stamp__c, c.Id);
                    lista.add(delCont);
                }
                if(!System.isFuture() && !System.isBatch() && !Test.isRunningTest())IntegratorMoradas.MoradaClienteDelete(JSON.serialize(lista));
            }
        }
    }
}