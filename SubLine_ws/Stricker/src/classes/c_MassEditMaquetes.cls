public class c_MassEditMaquetes {
    
    public List<Opportunity> opps {get;set;}
    public Opportunity myOpp {get;set;}
    public String retURL {get;set;}
    public boolean isBlocked {get;set;}
    public c_MassEditMaquetes(ApexPages.StandardSetController stdCtrl){
        retURL = stdCtrl.cancel().getUrl();
        
        opps = stdCtrl.getSelected();
        opps = [Select Id, Designer__c From Opportunity Where Id In :opps order by Data_do_pedido_de_maquete__c Asc];
        myOpp = new Opportunity();
        Set<Id> profileIds = new Map<Id, Profile>([Select id from Profile Where Id in (Select ProfileId From User Where Alias = 'DDE' Or Alias = 'SF')]).keySet();
        isBlocked = !profileIds.contains(UserInfo.getProfileId());
        if(isBlocked){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Disponivel_Designers));
        }
    }
    
    public void updateOpps(){
        if(myOpp.Designer__c != null){
            opps = [Select Id, Designer__c From Opportunity Where Id In :opps order by Data_do_pedido_de_maquete__c Asc];
            //2018-09-24
            //Apenas muda o estado das opps mais recentes, deixando a opp com a Data_do_pedido_de_maquete__c mais antiga com o estado a null, para que o Process Builder possa alterar o estado para 'Em construção'
            boolean isFirst = true;
            
            for(Opportunity o : opps){
                if(o.Designer__c == '' || o.Designer__c == null) {
                    //salta a primeira opp
                    if(isFirst){
                        isFirst = false;
                    }else{
                        //mete as seguintes em 'Suspenso'
                        o.Estado_da_maquete__c = 'Suspenso';
                        o.StageName = 'Maquete';
                    }
                    
                    o.Designer__c = myOpp.Designer__c;
                }
            }
            if(!opps.isEmpty()) update opps;
        }
    }
}