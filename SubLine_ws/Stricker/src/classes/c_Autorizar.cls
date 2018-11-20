public class c_Autorizar {
    public Opportunity opp {get;set;}
    public boolean success {get;set;}
    public c_Autorizar(ApexPages.StandardController ctrl){
        system.debug('Inicializar construtor');
        opp = buildOpp(ctrl.getId());
    	success = false;
    }
    
    public void updateRecord(){
        Set<String> allowedProfile = new Set<String>();
        for(Profile_Id__mdt pimdt : [Select Id__c From Profile_Id__mdt Where DeveloperName = 'Administrador_do_sistema' Or DeveloperName = 'Director_Comercial']){
            allowedProfile.add(pimdt.Id__c);
            allowedProfile.add(pimdt.Id__c.left(15));
        }
        //DESAUTORIZAR
        if(opp.Autorizada__c != null){
            if(allowedProfile.contains(UserInfo.getProfileId())){
                if(!opp.Impresso__c){
                    try{
                        opp.Autorizada__c = null;
                        opp.StageName = 'Aberto';
                        update opp;
                        success = true;
                    }catch(Exception ex){
                        system.debug(ex.getMessage());
                    }
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Nao_desautorizar));
                }                
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Sem_perm_desautorizar));
            }
        }else //AUTORIZAR SE CRIADO
            if(opp.Stamp__c != '' && opp.Stamp__c != null){
            try{
                opp.Autorizada__c = [Select Id, Alias From User Where Id = :UserInfo.getUserId()].Alias;
                opp.Espera_de_integracao__c = true;
                opp.Versao_enviada__c = opp.Versao_enviada__c != null ? opp.Versao_enviada__c + 1 : 1;
                
                if(opp.RecordType.DeveloperName.contains('Folha_de_Obra')){
                    opp.StageName = 'Em produção';
                }else if(opp.RecordType.DeveloperName.contains('Nota_de_encomenda') && opp.Motivo_de_pendente__c == 'Aviado' ){
                    opp.StageName = 'Em processo de faturação';
                }
                else{
                    opp.StageName = 'Armazém';
                }
                update opp;
                success = true;
            }catch(Exception ex){
                try{
                    system.debug(ex.getMessage());
                    opp = buildOpp(opp.Id);
                    if(opp.Auxiliar_total_de_produtos__c == opp.Auxiliar_expedicao__c) opp.Para_aprovacao__c = true;
                    update opp;
                }catch(Exception ex2){}
            }
        }else{//NÃO AUTORIZAR
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Dossier_nao_criado));
        }
    }
    
    public void reCheckIntegration(){
        opp = buildOpp(opp.Id);
    }
    
    public Opportunity buildOpp(String oppId){
        return [Select Id, RecordType.DeveloperName, Name, Autorizada__c,Impresso__c, Espera_de_integracao__c, Stamp__c, Auxiliar_expedicao__c, Auxiliar_total_de_produtos__c, Motivo_de_pendente__c,Versao_enviada__c,
                (Select Id, Quantity From OpportunityLineItems) 
                From Opportunity Where Id = :oppId];
    }
    
    public void goBack(){
        success=true;
    }
}