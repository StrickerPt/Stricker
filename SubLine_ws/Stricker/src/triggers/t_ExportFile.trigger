trigger t_ExportFile on Opportunity (after update) {
    if(checkRecursive.runExpFile){
        checkRecursive.runExpFile = false;
        List<String> opps = new List<String>();
        
        /*Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Folha de Obra').getRecordTypeId(),
Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Nota de encomenda').getRecordTypeId()*/
        Set<Id> recordTypesId = new Map<Id, RecordType>([Select Id from RecordType Where SobjectType = 'Opportunity' And (DeveloperName = 'Folha_de_Obra' Or DeveloperName = 'Nota_de_encomenda')]).keySet();
        
        //system.debug(recordTypesId);
        for(Opportunity opp :Trigger.new){
            if(recordTypesId.contains(opp.RecordTypeId) && 
               Trigger.oldMap.get(opp.Id).StageName != opp.StageName && (opp.StageName == 'Em produção' || opp.StageName == 'Armazém' )){
                   opps.add(opp.Id);
               }
        }
        if(!opps.isEmpty() && !System.isFuture() && !System.isBatch()){
            sh_ExportFile.exportJob(opps);
        }
    }
}