public class c_SincronizarDossier {
    public Opportunity opp {get;set;}
    public boolean success {get;set;}
    public c_SincronizarDossier(ApexPages.StandardController ctrl){
        opp = [Select Id, Referencia_PHC__c,Stamp__c,Versao_enviada__c From Opportunity Where Id = :ctrl.getId()];
        success = false;
    }
    
    public void callSync(){
        if(opp.Referencia_PHC__c != '0' && opp.Referencia_PHC__c != null){
            //RP 07-11-2018 incrementacao versao enviada
            checkRecursive.runFalse();
            if(opp.Stamp__c != null){
                if(opp.Versao_enviada__c != null){
                    opp.Versao_enviada__c = opp.Versao_enviada__c + 1;
                }else{
                    opp.Versao_enviada__c = 1;
                }
                update opp;
            }
            Integrator.actDossier(new Set<Id>{opp.Id});
        }else{
            Integrator.criaDossier(opp.Id);
        }
        success = true;
    }
}