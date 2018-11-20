public class sh_UpsertDossierPHC implements Schedulable{
    public String oppId;
    public boolean isInsert;
    public sh_UpsertDossierPHC(String oppId, boolean isInsert){
        this.oppId = oppId;
        this.isInsert = isInsert;
    }
    
    public void execute(SchedulableContext SC) {
        job(oppId, isInsert);
    }
    
    @future(callout=true)
    public static void job(String oppId, boolean isInsert){
        boolean scheduleAsync = false;
        
        Opportunity opp = Integrator.getOpp(oppId);
        opp.Espera_de_integracao__c = false;
        if(isInsert) scheduleAsync = Integrator.criaDossierWork(opp);
        //Keidy - Alteração do metodo para receber o mexeLinhas como parametro
        else scheduleAsync = Integrator.actDossierDoWork(opp, true);
        
        if(scheduleAsync){
            
            DateTime now  = DateTime.now();
            String nowToString = String.ValueOf(now);
            DateTime nextRunTime = now.addSeconds(10);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            
            opp = [Select Id, Stamp__c From opportunity Where Id = :opp.Id];
            sh_UpsertDossierPHC sc = new sh_UpsertDossierPHC(opp.Id, opp.Stamp__c == null);
            System.schedule('sh_UpsertDossierPHC - Upsert dossier ' + opp.Id + ' - '+ nowToString, cronString, sc);
        }
    }
}