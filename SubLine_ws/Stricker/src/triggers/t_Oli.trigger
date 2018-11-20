trigger t_Oli on OpportunityLineItem (before update, after update) {
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            
            Set<Id> expeditionsIds = new Set<Id>();
            Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>([Select Id, Nao_calcula_portes_automaticos__c From Opportunity Where Id In (Select OpportunityId From OpportunityLineItem Where Id In :Trigger.new)]);
            for(OpportunityLineItem oli : Trigger.new){
                if(oppsMap.containsKey(oli.OpportunityId)){
                    if((oli.Peso__c != Trigger.oldMap.get(oli.Id).Peso__c || oli.Volume__c != Trigger.oldMap.get(oli.Id).Volume__c)
                       && oli.Expedicao__c != null){
                        if(!oppsMap.get(oli.OpportunityId).Nao_calcula_portes_automaticos__c){
                            expeditionsIds.add(oli.Expedicao__c);
                        }
                    }                    
                }
            }
            
            if(!expeditionsIds.isEmpty() && (checkRecursive.runOpportunityAfterUpdate || checkRecursive.runRecalcExp)) {
                DateTime now  = DateTime.now();
                String nowToString = String.ValueOf(now);
                DateTime nextRunTime = now.addSeconds(10);
                String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
                
                b_RecalcExpedition sc = new b_RecalcExpedition(expeditionsIds);
                System.schedule('b_RecalcExpedition' + ' - '+ nowToString + ' User: ' + UserInfo.getUserId(), cronString, sc);
            }
        }
    }
    else{
        if(Trigger.isUpdate){
            Map<Id, Product2> prodsMap = new Map<Id, Product2>([Select Id, Peso__c, Volume__c From Product2 Where Id In (Select Product2Id From OpportunityLineItem Where Id In :Trigger.new)]);
            for(OpportunityLineItem oli : Trigger.new){
                if(prodsMap.containsKey(oli.Product2Id)){
                    if(oli.Peso__c == 0 || oli.Peso__c == null){
                        Decimal pesoProd = prodsMap.get(oli.Product2Id).Peso__c;
                        oli.Peso__c = pesoProd != null ? pesoProd * oli.Quantity : 0;
                    }
                    if(oli.Volume__c == 0 || oli.Volume__c == null){
                        
                        Decimal volProd = prodsMap.get(oli.Product2Id).Volume__c;
                        oli.Volume__c = volProd != null ? volProd * oli.Quantity : 0;
                    }
                }
            }
        }
    }
}