trigger t_Contact on Contact (after insert, after update, before delete) {
    if(checkRecursive.runContact){
        checkRecursive.runContact = false;
        if(Trigger.isAfter){
            if(Trigger.isUpdate){
                List<Schema.FieldSetMember> queryFields = SObjectType.Contact.FieldSets.Integration_Fields.getFields(); 
                Set<Id> contactIds = new Set<Id>();
                for(Id contactId : Trigger.newMap.keySet()){
                    
                    Boolean isChange = false;
                    sObject newCon = (sObject)Trigger.newMap.get(contactId);
                    sObject oldCon = (sObject)Trigger.oldMap.get(contactId);
                    for(Schema.FieldSetMember field : queryFields){
                        if(newCon.get(field.getFieldPath()) != oldCon.get(field.getFieldPath())){
                            isChange = true;
                            break;
                        }
                    }
                    
                    if(isChange){
                        contactIds.add(contactId);
                    }
                    
                }
                
                //@toDo webservice call
                if(!contactIds.isEmpty()){
                    Integrator.contactUpsert(contactIds);
                }
                
            }else if(Trigger.isInsert){
                if(!System.isFuture() && !System.isBatch())Integrator.contactUpsert(Trigger.newMap.keySet());
            }
        }else{
            if(Trigger.isDelete){
                List<Integrator.DeleteContact> lista = new List<Integrator.DeleteContact>();
                for(Contact c : Trigger.old){
                    Integrator.DeleteContact delCont = new Integrator.DeleteContact(c.Stamp__c, c.Id);
                    lista.add(delCont);
                }
                if(!System.isFuture() && !System.isBatch())Integrator.contactDelete(JSON.serialize(lista));
            }
        }
    }
}