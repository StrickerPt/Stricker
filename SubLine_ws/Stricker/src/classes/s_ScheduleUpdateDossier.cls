global class s_ScheduleUpdateDossier implements Schedulable{
    public Set<Id> oppIds;
    
    public s_ScheduleUpdateDossier(Set<Id> oppIds){
        this.oppIds = oppIds;
    }
    
    global void execute(SchedulableContext SC) {
        //RP 07-11-2018 incrementacao versao enviada
        checkRecursive.runFalse();
        List<Opportunity> l_oppsUpdate = new List<Opportunity>();
        for(Opportunity opp : [Select Id, Referencia_PHC__c,Stamp__c,Versao_enviada__c From Opportunity Where Id in :oppIds]){
            if(opp.Stamp__c != null){
                opp.Espera_de_integracao__c = true;
                if(opp.Versao_enviada__c != null){
                    opp.Versao_enviada__c = opp.Versao_enviada__c + 1;
                }else{
                    opp.Versao_enviada__c = 1;
                }
                l_oppsUpdate.add(opp);
            }
        }
        if(!l_oppsUpdate.isEmpty()){
            update l_oppsUpdate;
        }
        Integrator.actDossier(oppIds);
    }    
}