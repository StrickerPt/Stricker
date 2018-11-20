public class c_AdminPage {
    public Batch dossiers {get;set;}
    public Batch dossiersWeb {get;set;}
    
    public c_AdminPage(){
        init();
    }
    public void init(){
        dossiers = new Batch();
        dossiersWeb = new Batch();
        for(CronTrigger job :[SELECT Id, CronJobDetail.Name, NextFireTime FROM CronTrigger Where State = 'WAITING' And PreviousFireTime = null]){
            /*if(job.CronJobDetail.Name.contains('b_UpdateDossierWeb')){
                dossiersWeb.running = true;
                dossiersWeb.agendamentos.add(new CronWrapper(job.NextFireTime.format(), job.Id));
            }else if(job.CronJobDetail.Name.contains('b_UpdateDossier')){
                dossiers.running = true;
                dossiers.agendamentos.add(new CronWrapper(job.NextFireTime.format(), job.Id));
            }*/
        }
    }
    //CORRER BATCHES
    public void correrBatchDossier(){
        if(dossiers.pagina != null)
            new b_UpdateDossier().execute(null);
    }
    public void correrBatchDossierWeb(){
        if(dossiersWeb.pagina != null)
            new b_UpdateDossierWeb().execute(null);
    }
    /////*******************
    
    //TERMINAR BATCHES
    public void terminarBatchDossier(){
        shutDownCron(dossiers.agendamentos);
        init();
    }
    
    public void terminarBatchDossierWeb(){
        shutDownCron(dossiersWeb.agendamentos);
        init();
    }
    
    private void shutDownCron(List<CronWrapper> wrappers){
        for(CronWrapper cron : wrappers){
            if(cron.selected){
                System.abortJob(cron.cronId);
            }
        }
    }
    /////*******************
    public class Batch{
        public boolean running {get;set;}
        public List<CronWrapper> agendamentos {get;set;}
        public Integer pagina {get;set;}
        
        public Batch(){
            agendamentos = new List<CronWrapper>();
            running = false;
        }
    }
    
    public class CronWrapper{
        public boolean selected {get;set;}
        public String dataAgend {get;set;}
        public String cronId {get;set;}
        
        public CronWrapper(String dataAgend, String cronId){
            this.selected = false;
            this.dataAgend = dataAgend;
            this.cronId = cronId;
        }
    }
}