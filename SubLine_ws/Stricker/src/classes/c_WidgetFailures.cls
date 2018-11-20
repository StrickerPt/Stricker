public with sharing class c_WidgetFailures {
    public List<Dossier> myDossiers {get;set;}
    private Set<Id> myOppIds {get;set;}
    public boolean showAlert {get;set;}
    public Profile_Id__mdt profileMtd {get;set;}
    public static final String dateCondition = ' And CreatedDate > 2018-11-05T00:00:00Z'//data a partir do qual este componente foi para prod
        + ' And (N_de_expedicao__c = null Or N_de_expedicao__c = \'0\')';
    public c_WidgetFailures(){
        profileMtd = [Select id__c from Profile_Id__mdt  where DeveloperName = 'widgetFailuresAdmins' limit 1];

        String whereCondition = '';
        if(profileMtd != null && profileMtd.Id__c.contains(UserInfo.getProfileId())){
            whereCondition = 'Erro_comunicacao__c = true' + dateCondition;
        }
        else{
            whereCondition = 'Erro_comunicacao__c = true' + ' and Owner.Id = \'' + UserInfo.getUserId() + '\'' + ' and Account.Assistente_comercial__r.Id = \'' + UserInfo.getUserId() + '\'' + dateCondition;
        }
        
        myDossiers = new List<Dossier>();
        myOppIds = new Set<Id>();
        showAlert = false;
        for(Opportunity opp : getOpps(whereCondition)){
            if(opp.Description != '' && opp.Description != null){
                myDossiers.add(new Dossier(opp, false));
                myOppIds.add(opp.Id);
            }
        }
    }
    
    public void checkNewErrors(){
        String whereCondition = '';
        if(profileMtd != null && profileMtd.Id__c.contains(UserInfo.getProfileId())){
            whereCondition = 'Erro_comunicacao__c = true and Id Not In :myOppIds' + dateCondition;
            
        }
        else{
            whereCondition = 'Erro_comunicacao__c = true and Id Not In :myOppIds' + ' and Owner.Id = \'' + UserInfo.getUserId() + '\'' + ' and Account.Assistente_comercial__r.Id = \'' + UserInfo.getUserId() + '\'' + dateCondition;
        }
        
        showAlert = false;
        for(Opportunity opp : getOpps(whereCondition)){
            if(opp.Description != '' && opp.Description != null){
                myDossiers.add(new Dossier(opp, true));
                myOppIds.add(opp.Id);
                showAlert = true;
            }
        }
        whereCondition = '';
        if(profileMtd != null && profileMtd.Id__c.contains(UserInfo.getProfileId())){
            whereCondition = 'Id In :myOppIds and Erro_comunicacao__c = false' + dateCondition;
        }
        else{
            whereCondition = 'Id In :myOppIds and Erro_comunicacao__c = false' + ' and Owner.Id = \'' + UserInfo.getUserId() + '\'' + ' and Account.Assistente_comercial__r.Id = \'' + UserInfo.getUserId() + '\'' + dateCondition;
        }
        
        List<Dossier> aux = new List<Dossier>();
        Set<Id> freeOps = new Map<Id, Opportunity>(getOpps(whereCondition)).keySet();
        myOppIds.clear();
        for(Dossier dos : myDossiers){
            if(!freeOps.contains(dos.opp.Id)){
                aux.add(dos);
                myOppIds.add(dos.opp.Id);
            }
        }
        myDossiers.clear();
        
        myDossiers.addAll(aux);
        
        myDossiers.sort();
    }
    
    public List<Opportunity> getOpps(String whereClause){
        String query = 'Select Id, Name, Description, AccountId, Account.Name, LastModifiedDate From Opportunity';
        
        query += whereClause != '' ? ' Where ' + whereClause : '';
        
        query += ' Order By LastModifiedDate Desc';
        
        return Database.query(query);
    }
    
    public String sendId {get;set;}
    public Boolean hasError {get;set;}
    public String errorMsg {get;set;}
    public void resendDossier(){
        hasError = false;
        errorMsg = '';
        try{
            if(sendId != null && myOppIds.contains(sendId)){
                Opportunity sendOpp;
                try{
                    sendOpp = [Select Id, Referencia_PHC__c,Stamp__c,Versao_enviada__c from Opportunity where Id = :sendId];
                }catch(Exception ex){
                    system.debug(sendOpp);
                }
                if(sendOpp != null){
                    //RP 07-11-2018 incrementacao versao enviada
                    checkRecursive.runFalse();
                    sendOpp.Espera_de_integracao__c = true;
                    sendOpp.Erro_comunicacao__c = false;
                    if(sendOpp.Stamp__c != null){
                        if(sendOpp.Versao_enviada__c != null){
                            sendOpp.Versao_enviada__c = sendOpp.Versao_enviada__c + 1;
                        }else{
                            sendOpp.Versao_enviada__c = 1;
                        }
                    }
                        
                    update sendOpp;
                    if(sendOpp.Referencia_PHC__c != null && sendOpp.Referencia_PHC__c != '' && sendOpp.Referencia_PHC__c != '0'){
                        Integrator.actDossier(new Set<Id>{sendId});
                    }else{
                        Integrator.criaDossier(sendId);
                    }
                    List<Dossier> aux = new List<Dossier>();
                    myOppIds.remove(sendId);
                    //reconstroi lista para remover o dossier
                    for(Dossier dos : myDossiers){
                        if(dos.opp.Id != sendId){
                            aux.add(dos);
                        }
                    }
                    myDossiers.clear();
                    
                    myDossiers.addAll(aux);
                    
                    myDossiers.sort();
                }
            }
        }catch(Exception ex){
            hasError = true;
            errorMsg = Label.Erro_tente_novamente;
        }
    }
    public class Dossier implements Comparable{
        public Opportunity opp {get;set;}
        public boolean isNew {get;set;}
        
        public Dossier(Opportunity opp, boolean isNew){
            this.opp = opp;
            this.isNew = isNew;
        }
        
        public Integer compareTo(Object compareTo) {
            Dossier compareToDoss = (Dossier)compareTo;
            Integer returnValue = 0;
            
            if(opp.LastModifiedDate < compareToDoss.opp.LastModifiedDate){
                returnValue = 1;       
            }else if(opp.LastModifiedDate > compareToDoss.opp.LastModifiedDate){
                returnValue = -1;   
            }
            return returnValue;
        }
    }
}