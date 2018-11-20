@isTest
public class Test_UpdateOpportunity {
    static testmethod void t_UpdateOpportunity() {
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        s_UpdateOpportunity upOpp = new s_UpdateOpportunity(result.opp.Id);
        upOpp.execute(null);
        
        s_ScheduleUpdateDossier upOpp2 = new s_ScheduleUpdateDossier(new Set<Id>{result.opp.Id});
        upOpp2.execute(null);
    }
}