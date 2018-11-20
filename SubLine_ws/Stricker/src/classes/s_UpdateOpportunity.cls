global class s_UpdateOpportunity implements Schedulable {

    public Id oppId;
    public s_UpdateOpportunity(Id oppId){
        this.oppId = oppId;
    }
    
    global void execute(SchedulableContext SC) {
        Integrator.actDossier(new Set<Id>{oppId});
    }
}