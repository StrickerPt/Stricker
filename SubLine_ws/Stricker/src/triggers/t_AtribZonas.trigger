trigger t_AtribZonas on Atribuicao_de_zonas__c (after update) {
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            List<Schema.FieldSetMember> queryFields = SObjectType.Atribuicao_de_zonas__c.FieldSets.CamposAtribuicao.getFields();
            Set<String> countries = new Set<String>();
            for(Id atbId : Trigger.newMap.keySet()){
                Boolean isChange = false;
                
                
                sObject newAtb = (sObject)Trigger.newMap.get(atbId);
                sObject oldAtb = (sObject)Trigger.oldMap.get(atbId);
                for(Schema.FieldSetMember field : queryFields){
                    if(newAtb.get(field.getFieldPath()) != oldAtb.get(field.getFieldPath())){
                        isChange = true;
                        break;
                    }
                }
                
                if(isChange){
                     countries.add(Trigger.newMap.get(atbId).Pais__c);
                }
            }
            if(!countries.isEmpty()){
                b_AtribZonasLeads atbL = new b_AtribZonasLeads(countries, true);
                b_AtribZonasAccounts atbAcc = new b_AtribZonasAccounts(countries, true);
            }
        }
    }
}