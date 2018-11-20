public class c_ValidarMoradaOnline {
    public List<SelectedAddress> moradas {get;set;}
    public Opportunity opp {get;set;}
    public boolean addressCreated {get;set;}
    public boolean addressAssociated {get;set;}
    public boolean doPage {get;set;}
    public c_ValidarMoradaOnline(ApexPages.StandardController ctrl){
        opp = [Select id, Codigo_postal_online__c, AccountId, Morada_de_entrega_online__c, Pais_online__c, Localidade_online__c, Telefone_logistico__c, Ao_cuidado_de_online__c From Opportunity Where Id = :ctrl.getRecord().Id];
        moradas = new List<SelectedAddress>();
        addressCreated = false;
        addressAssociated = false;
        for(Morada_de_entrega__c mor : [Select Id, Name, Morada_de_entrega__c, Localidade__c,Codigo_postal__c, Pais__c
                                        From Morada_de_entrega__c 
                                        Where Conta__c = :opp.AccountId And (Codigo_Postal__c = :opp.Codigo_postal_online__c)]){
            moradas.add(new SelectedAddress(mor));
        }
        doPage = !moradas.isEmpty();
    }
    
    public void criarNovaMorada(){
        if(opp.Codigo_postal_online__c != null && opp.Morada_de_entrega_online__c != null){
            Morada_de_entrega__c novaMorada = new Morada_de_entrega__c();
            novaMorada.Codigo_postal__c = opp.Codigo_postal_online__c;
            novaMorada.Morada_de_entrega__c = opp.Morada_de_entrega_online__c;
            novaMorada.Pais__c = opp.Pais_online__c;
            novaMorada.Conta__c = opp.AccountId;
            novaMorada.Localidade__c = opp.Localidade_online__c;
            novaMorada.Telefone_logistico__c = opp.Telefone_logistico__c;
            novaMorada.Nome_da_empresa__c = opp.Ao_cuidado_de_online__c;
            
            try{
                insert novaMorada;
                addressCreated = true;
            }catch(Exception ex){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,
                                                           'Something went wrong: ' + (ex.getTypeName() == 'System.DmlException' ? ex.getdmlMessage(0) :
                                                                                       ' contact the system admin.' + ex.getMessage())));
            }
        }
    }
    
    public void associarMorada(){
        SelectedAddress selected;
        for(SelectedAddress sa : moradas){
            if(sa.selected){
                selected = sa;
                break;
            }
        }
        if(selected != null){
            try{
                opp.id_Morada_de_entrega__c = selected.address.Id;
                update opp;
                addressAssociated = true;
            }catch(Exception ex){ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Something went wrong: ' + (ex.getTypeName() == 'System.DmlException' ? ex.getdmlMessage(0) : ' contact the system admin.' + ex.getMessage())));
            }
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select an address to merge.'));
        }
    }
    
    public void clearMessages(){
        ApexPages.getMessages().clear();
    }
    
    public class SelectedAddress{
        
        public boolean selected {get;set;}
        public Morada_de_entrega__c address {get;set;}
        
        public SelectedAddress(Morada_de_entrega__c address){
            this.address = address;
            selected = false;
        }
    }
}