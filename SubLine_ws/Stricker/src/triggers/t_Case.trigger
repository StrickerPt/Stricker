trigger t_Case on Case (before insert, after insert,after update, before delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            //tirar snapshot do caso para mostrar alertas
            Set<Id> accIds = new Set<Id>();
            Set<String> boStamps = new Set<String>();
            for(Case caso: Trigger.new){
                accIds.add(caso.AccountId);
                boStamps.add(caso.BoStamp_dossier_original__c);
            }
            Map<Id,Account> accs = new Map<Id,Account>([select id,Encomendas_canceladas__c, Divida_vencida__c,
                                                        (Select id From Opportunities Where Stamp__c Not in :boStamps),
                                                        (Select Id From Cases Where CreatedDate > :System.today().addMonths(-3))
                                                        from Account 
                                                        Where Id In :accIds]);
            
            for(Case caso: Trigger.new){
                
                //caso.Cliente_VIP__c  - FALTAM OS CRITERIOS PARA SER CLIENTE VIP
                caso.Cliente_com_encomendas_canceladas__c = accs.get(caso.AccountId).Encomendas_canceladas__c;
                caso.Cliente_com_divida_vencida__c = accs.get(caso.AccountId).Divida_vencida__c != null && accs.get(caso.AccountId).Divida_vencida__c != null;
                caso.N_dossiers_cliente_sem_reclamacao__c = accs.get(caso.AccountId).Opportunities.size();
                caso.Cliente_mais_de_3_reclamacoes__c = accs.get(caso.AccountId).Cases.size() > 3;
                caso.N_de_reclamacoes_do_cliente__c = accs.get(caso.AccountId).Cases.size();
                
            }
            
        }else if(Trigger.isDelete){
            delete [Select id from Order where Reclamacao__c In :Trigger.old];
        }
    }else{
        if(checkRecursive.runCase){
            checkRecursive.runCase = false;
            if(Trigger.isInsert){
                for(Case caso : Trigger.new){
                    IntegratorClaims.createClaim(caso.Id);
                }
            }else if(Trigger.isUpdate){
                for(Case caso : Trigger.new){
                    IntegratorClaims.updateClaim(caso.Id);
                }
                
            }
        }
    }
}