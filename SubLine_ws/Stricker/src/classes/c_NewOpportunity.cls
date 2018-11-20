public class c_NewOpportunity {
    public List<SelectOption> rtOptions {get;set;}
    public String selectedRT {get;set;}
    public Opportunity opp {get;set;}
    public String accId {get;set;}
    public List<RecordType> recordTypes {get;set;}
    public String foRecordId {get;set;}
    public String foiRecordId {get;set;}
    public String neRecordId {get;set;}
    public Map<String, String> auxRtMap {get;set;}
    public String accTipoFat {get;set;}
    
    public c_NewOpportunity(ApexPages.StandardController stdCtrl){
        getRecordTypes();
        foRecordId = auxRtMap.get('Folha_de_Obra');
        foiRecordId = auxRtMap.get('Folha_de_Obra_de_Importacao');
        neRecordId = auxRtMap.get('Nota_de_encomenda');
        system.debug(stdCtrl);
        accId = apexpages.currentpage().getparameters().get('accid');
        rtOptions = new List<SelectOption>();
        rtOptions.add(new SelectOption('', '--'));
        for(Schema.RecordTypeInfo rt : Schema.SObjectType.Opportunity.getRecordTypeInfosByName().values()){
            if(!rt.isMaster() && rt.isActive()){
                rtOptions.add(new SelectOption(rt.getRecordTypeId(), rt.getName())); 
            }
        }
        accTipoFat = '';
        recordTypes = [Select Id, Name, Description, DeveloperName From RecordType Where SobjectType = 'Opportunity' and isActive = true];
    }
    
    public void getRecordTypes(){
        List<RecordType> rTypes = [Select id, Name, DeveloperName From RecordType Where SobjectType = 'Opportunity'];
        auxRtMap = new Map<String, String>();
        for(RecordType rt : rTypes){
            auxRtMap.put(rt.DeveloperName, rt.Id);
        }
    }
    
    public void createDummyOpp(){

        if(selectedRT != null){
            opp = new Opportunity();
            opp.RecordTypeId = selectedRT;
            String rtName = '';
            String rtDevName = [Select DeveloperName From RecordType Where Id = :selectedRT].DeveloperName;
            for(Schema.RecordTypeInfo rt : Schema.SObjectType.Opportunity.getRecordTypeInfosByName().values()){
                if(rt.getRecordTypeId() == selectedRt){
                    rtName = rt.getName();
                    break;
                }
            }
            opp.Name = rtName;
            if(rtDevName.contains('Orcamento')){
                opp.CloseDate = System.today().addDays(3);
            }else{
                opp.CloseDate = System.today().addDays(30);
            }
            
            opp.Validade__c = rtName.contains('Orçamento') ?  System.today().addDays(7): null;
            //opp.AccountId = accId;
            List<Account> acc =  [Select Documento_de_Destino__c,Tipologia_de_facturacao__c From Account Where Id =:accId];
            if(!acc.isEmpty()){
                opp.AccountId = accId;
                opp.Documento_de_destino__c = acc.get(0).Documento_de_destino__c;
                //opp.Account = new Account();
                accTipoFat = acc.get(0).Tipologia_de_facturacao__c;
            }
            opp.OwnerId = UserInfo.getUserId();
            opp.StageName = 'Aberto';
            opp.Armazem__c = '1';
        }else{
            opp = null;
        }
    }
    
    public void docDest(){
        if(opp.AccountId != null){
            try{
                List<Account> acc =  [Select Documento_de_Destino__c,Tipologia_de_facturacao__c From Account Where Id =:opp.AccountId];
                if(!acc.isEmpty()){
                    opp.Documento_de_destino__c = acc.get(0).Documento_de_destino__c;
                    //opp.Account = new Account();
                    accTipoFat = acc.get(0).Tipologia_de_facturacao__c;
                }else{
                    accTipoFat = '';
                    opp.Documento_de_destino__c = '';
                }
            }catch(Exception ex){}
        }
    }
    
    public void insertOpp(){
        if(opp.AccountId == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Mandatory_Account_on_Opp));
        }else if(!(opp.RecordTypeId == auxRtMap.get('Orcamento') || opp.RecordTypeId == auxRtMap.get('Orcamento_de_Importacao')) && (opp.Documento_de_destino__c == null || opp.Destino_de_impressao__c == null)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Campos_Obrigatorios_Docs));
        }else if((opp.RecordTypeId == foRecordId || opp.RecordTypeId == foiRecordId) && (opp.Email_para_envio_de_maquete__c == '' || opp.Email_para_envio_de_maquete__c == null)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, label.Campos_Obrigatorios_Email));
        }else if((opp.RecordTypeId == foRecordId || opp.RecordTypeId == foiRecordId || opp.RecordTypeId == neRecordId) &&
                 (opp.Armazem__c == '' || opp.Armazem__c == null)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, label.Campos_obrigatorios));
        }else{
            try{
                opp.CurrencyIsoCode = ProductManager.mapISOCodes.get([Select Tabela_de_Precos__c From Account Where Id = :opp.AccountId Limit 1].Tabela_de_Precos__c);
                system.debug(opp);
                insert opp;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Sucess!'));
            }catch(Exception ex){
                system.debug('Something failed: ' + (ex.getTypeName() == 'System.DmlException' ? ex.getdmlMessage(0) : ' contact the system admin. '+ ex.getMessage() + ex.getLineNumber()));
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Something went wrong: ' + (ex.getTypeName() == 'System.DmlException' ? ex.getdmlMessage(0) :' contact the system admin.' + ex.getMessage())));
            }
        }
    }
}