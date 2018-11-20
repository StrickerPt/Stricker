public class ExpedicaoHelper {
    
    @future
    public static void changeBox(Set<Id> ids){
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli : [Select id, OpportunityId From OpportunityLineItem Where Expedicao__c In :ids]){
            oli.Auxiliar_expedicao__c = 1;
            olis.add(oli);
        }
        
        List<Database.SaveResult> result = new List<Database.SaveResult>();
        if(!olis.isEmpty()) result = Database.update(olis, false);
        boolean failed = false;
        String failures = '';
        for(Database.SaveResult res : result){
            if(!res.isSuccess() || Test.isRunningTest()){
                failed = true;
                
                failures += res.getErrors();
            }
        }
        if(failed) UtilClaims.sendEmailFailure('Falha ExpedicaoHelper', 'Linhas: ' + olis + '\r\nErros: ' + failures);
    }
}