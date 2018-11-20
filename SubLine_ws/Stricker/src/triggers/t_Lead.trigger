trigger t_Lead on Lead (after insert, after update) {
    if(Trigger.IsAfter){
        if(Trigger.isUpdate){
            if(checkRecursive.runLead){
                checkRecursive.runLead = false;
                Set<Id> leadsToConvert = new Set<Id>();
                Set<Id> leadsToUpdateAtrib = new Set<Id>();
                List<Schema.FieldSetMember> queryFields = SObjectType.Lead.FieldSets.CamposAtribuicao.getFields();
                
                for(Lead l : Trigger.new){
                    if(l.Aprovado__c && !l.isConverted){
                        leadsToConvert.add(l.Id);
                    }
                    
                    
                    Boolean isChange = false;
                    
                    sObject newLead = (sObject)Trigger.newMap.get(l.Id);
                    sObject oldLead = (sObject)Trigger.oldMap.get(l.Id);
                    for(Schema.FieldSetMember field : queryFields){
                        if(newLead.get(field.getFieldPath()) != oldLead.get(field.getFieldPath())){
                            isChange = true;
                            break;
                        }
                    }
                    
                    if(isChange){
                        leadsToUpdateAtrib.add(l.Id);
                    }
                }
                
                if(!leadsToConvert.isEmpty()) IntegratorClientes.createCustomer(leadsToConvert);
                if(!leadsToUpdateAtrib.isEmpty()) b_AtribZonasLeads atb = new b_AtribZonasLeads(leadsToUpdateAtrib, true);
            }
        }else if(Trigger.isInsert){
            b_AtribZonasLeads atb = new b_AtribZonasLeads(Trigger.newMap.keySet(), true);
        }
    }
}