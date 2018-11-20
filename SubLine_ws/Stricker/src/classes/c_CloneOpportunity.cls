public class c_CloneOpportunity {
    private Auxiliar_Clone_Dossier__c aux = new Auxiliar_Clone_Dossier__c();
    public List<String> allowedRts {get;set;}
    public Map<String, String> auxRtMap {get;set;}
    public Map<String, String> rtIcons {get;set;}//RtName=>IconAPIName
    public String pickedRt {get;set;}
    public Opportunity opp;
    public boolean success {get;set;}
    public List<SelectedProd> olis {get;set;}
    public Opportunity newOpp {get;set;}
    
    public boolean calcPrecos {get;set;}
    
    public c_CloneOpportunity(ApexPages.StandardController controller){
		
        getRecordTypes();
        calcPrecos = false;
        rtIcons = new Map<String,String>{
            'Folha_de_Obra' => 'custom_apps',
            'Nota_de_encomenda' => 'copy_to_clipboard',
            'Orcamento' => 'moneybag',
            'Folha_de_Obra_de_Importacao' => 'custom_apps',
            'Orcamento_de_Importacao' => 'moneybag',
            'Reserva' => 'edit_form'};
            
        olis = new List<SelectedProd>();
        success = false;
        
        this.opp = [select Id,RecordType.DeveloperName from Opportunity where Id =:controller.getId()];
        aux = Auxiliar_Clone_Dossier__c.getValues(opp.RecordType.DeveloperName);
        allowedRts = aux.Rts_Permitidos__c.split(';');
        system.debug(allowedRts);
        String oliQuery = 'Select ';
        boolean isFirst = true;
        for(String s : Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().keySet()){
            if(isFirst){
                isFirst= false;
            }else{
                oliQuery += ',';
            }
            oliQuery += s;
        }
        oliQuery += ' From OpportunityLineItem Where OpportunityId  = \'' +opp.Id+ '\' And Product2.RecordType.DeveloperName = \'Produto\'';
        for(OpportunityLineItem oli : Database.query(oliQuery)){
            olis.add(new SelectedProd(false, oli));
        }
    }
    
    public void getRecordTypes(){
        List<RecordType> rTypes = [Select id, Name, DeveloperName From RecordType Where SobjectType = 'Opportunity'];
        auxRtMap = new Map<String, String>();
        for(RecordType rt : rTypes){
            auxRtMap.put(rt.DeveloperName, rt.Id);
        }
    }
    public void clonarDossier(){

        String query = 'SELECT ';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap();
        boolean isFirst = true;
        for(String s : objectFields.keySet()) {
            if(isFirst){
                isFirst= false;
            }else{
                query += ',';
            }
            query += s;
        }
        
        query += ' ,Account.Escalao_Hidea__c, Account.Tabela_de_precos__c From Opportunity Where Id = \'' +opp.Id+ '\'';
        
        opp = Database.query(query);
        
        //***********************************Criação do clone
        Opportunity newOpp = opp.clone();
        system.debug(pickedRt);
        system.debug(pickedRt);
        newOpp.RecordTypeId = auxRtMap.get(pickedRt);
        newOpp.Stamp__c = '';
        newOpp.StageName = 'Aberto';
        newOpp.Referencia_PHC__c = '';
        newOpp.Referencia_interna__c = '';
        newOpp.Nweb__c = '';
        newOpp.Autorizada__c = '';
        newOpp.Description = '';
        newOpp.Impresso__c = false;
        newOpp.Espera_de_integracao__c = newOpp.RecordTypeId == auxRtMap.get('Nota_de_encomenda') || newOpp.RecordTypeId == auxRtMap.get('Folha_de_Obra');
        newOpp.Erro_comunicacao__c = false;
        
        Map<Id, NovoProduto> newProds = new Map<Id, NovoProduto>();
        Set<Id> productCodes = new Set<Id>();
        //Verifica produtos seleccionados
        for(SelectedProd oli : olis){
            if(oli.selected){
                NovoProduto np = new NovoProduto(oli.item);
                newProds.put(oli.item.Id, np);
                
                //juntar codigos de todos os produtos
                productCodes.add(oli.item.Product2Id);
            }
        }
        if(!newProds.isEmpty()){
            //cria nova oportunidade
            try{
                insert newOpp;
                if(Test.isRunningTest()){
                    newOpp.Pricebook2Id = Test.getStandardPricebookId();
                    update newOpp;
                }
                
                this.newOpp = newOpp;
                
                //Inicialização da estrutura para criação de novos produtos e respectivas customizações
                String oliQuery = 'Select ';
                isFirst = true;
                for(String s : Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().keySet()){
                    if(isFirst){
                        isFirst= false;
                    }else{
                        oliQuery += ',';
                    }
                    oliQuery += s;
                }
                Set<Id> prodKeyset = newProds.keySet();
                oliQuery += ' From OpportunityLineItem Where Referencia_Relacionada__c in :prodKeyset';
                
                for(OpportunityLineItem oli : Database.query(oliQuery)){
                    newProds.get(oli.Referencia_relacionada__c).customs.add(oli);
                    productCodes.add(oli.Product2Id);
                }
                String likeString = '%' + opp.Account.Tabela_de_precos__c;
                Id currentPb;
                if(!Test.isRunningTest()) 
                    currentPb = [Select Id From Pricebook2 Where Name Like :likeString Limit 1].Id;
                else
                    currentPb = Test.getStandardPricebookId();
                
                Map<Id, PricebookEntry> pbes = new Map<Id, PricebookEntry>();//Product2Id => PricebookEntry
                
                String pbeQuery = 'SELECT ';
                isFirst = true;
                for(String s : Schema.getGlobalDescribe().get('PricebookEntry').getDescribe().fields.getMap().keySet()) {
                    if(isFirst){
                        isFirst= false;
                    }else{
                        pbeQuery += ',';
                    }
                    pbeQuery += s;
                }
                String str = opp.CurrencyIsoCode;
                pbeQuery += ' From PricebookEntry Where Product2Id In :productCodes And Pricebook2Id = :currentPb And CurrencyIsoCode = \'' + opp.CurrencyIsoCode + '\'';
                
                system.debug('Current PB ' + currentPb);
                for(PricebookEntry pbe : Database.query(pbeQuery)){
                    pbes.put(pbe.Product2Id, pbe);
                }
                
                Map<Id, Preco_por_cliente__c> precosCliente = new Map<Id, Preco_por_cliente__c>();//IdProd - PC
                
                for(Preco_por_cliente__c pc : [Select Id, Produto__c, Valor__c
                                               From Preco_por_cliente__c 
                                               Where Produto__c in:productCodes 
                                               And Cliente__c In (Select AccountId From Opportunity Where Id = :opp.Id)]){
                                                   precosCliente.put(pc.Produto__c, pc);
                                               }
                
                //criação de novos produtos
                List<OpportunityLineItem> newItems = new List<OpportunityLineItem>();
                
                for(NovoProduto np : newProds.values()){
                    np.oli = np.oli.clone();
                    np.oli.Stamp__c = '';
                    np.oli.Lotes__c = '';
                    np.oli.OpportunityId = newOpp.Id;
                    np.oli.TotalPrice = null;
                    np.oli.Stock_cativo__c = pickedRt != 'Reserva';
                    np.oli.PricebookEntryId = pbes.get(np.oli.Product2Id).Id;
                    system.debug('This pbe.pb: ' + pbes.get(np.oli.Product2Id).Pricebook2Id);
                    if(calcPrecos){
                        calculaPreco(np.oli, pbes.get(np.oli.Product2Id), precosCliente);
                        if(newOpp.Amostra__c && newOpp.Tipo_de_amostra__c == 'Terceiros'){
                            np.oli.UnitPrice *= 0.05;
                            np.oli.Preco_Unitario__c *= 0.05;
                            np.oli.Total_de_customizacao__c *= 0.05;
                        }
                    }
                    
                    newItems.add(np.oli);
                }
                if(!newItems.isEmpty()) insert newItems;
                
                //criação de novas customizações para os respectivos produtos
                if(pickedRt != 'Nota de encomenda'){
                    List<OpportunityLineItem> newCustoms = new List<OpportunityLineItem>();
                    for(NovoProduto np : newProds.values()){
                        for(OpportunityLineItem custom : np.customs){
                            custom = custom.clone();
                            custom.Referencia_relacionada__c = np.oli.Id;
                            custom.Stamp__c = '';
                            custom.Lotes__c = '';
                            custom.OpportunityId = newOpp.Id;
                            custom.TotalPrice = null;
                            custom.PricebookEntryId = pbes.get(custom.Product2Id).Id;
                            custom.Stock_cativo__c = pickedRt != 'Reserva';
                            
                            if(calcPrecos){
                                calculaPreco(custom, pbes.get(custom.Product2Id), precosCliente);
                                if(newOpp.Amostra__c && newOpp.Tipo_de_amostra__c == 'Terceiros'){
                                    np.oli.UnitPrice *= 0.05;
                                    np.oli.Preco_Unitario__c *= 0.05;
                                    np.oli.Total_de_customizacao__c *= 0.05;
                                }
                            }
                            
                            newCustoms.add(custom);
                        }
                    }
                    if(!newCustoms.isEmpty()) insert newCustoms;
                }
                system.debug(newOpp.RecordTypeId == auxRtMap.get('Nota_de_encomenda'));
                system.debug(newOpp.RecordTypeId == auxRtMap.get('Folha_de_Obra'));
                if(opp.RecordTypeId == auxRtMap.get('Reserva') &&
                   (newOpp.RecordTypeId == auxRtMap.get('Nota_de_encomenda')
                   || newOpp.RecordTypeId == auxRtMap.get('Folha_de_Obra'))){
                       
                       List<OpportunityLineItem> descativar = new List<OpportunityLineItem>();
                       for(SelectedProd np : olis){
                           np.item.Stock_cativo__c = false;
                           descativar.add(np.item);
                       }
                       
                       update descativar;
                       
                       opp.StageName = 'Fechado concluído';
                       update opp;
                       
                       Integrator.criaDossier(newOpp.Id);
                       
                   }else 
                       if(newOpp.RecordTypeId == auxRtMap.get('Nota_de_encomenda') || newOpp.RecordTypeId == auxRtMap.get('Folha_de_Obra')){
                       Integrator.criaDossier(newOpp.Id);
                   }
                
                success = true;
            }catch(Exception ex){system.debug(ex.getMessage() + ' ' + ex.getLineNumber());}
        }else if(!olis.isEmpty()){
            //selecionar produtos
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Selecionar_Produtos));
        }else{
            
            insert newOpp;
            if(Test.isRunningTest()){
                newOpp.Pricebook2Id = Test.getStandardPricebookId();
                update newOpp;
            }
            newOpp = newOpp;
            success = true;
        }
    }
    
    public void calculaPreco(OpportunityLineItem oli, PricebookEntry pbe, Map<Id, Preco_por_cliente__c> precosCliente){
        
        //Calcular Preço
        if(precosCliente.containsKey(pbe.Product2Id)){
            Decimal newPrice = precosCliente.get(pbe.Product2Id).Valor__c;
            oli.UnitPrice = newPrice;
            oli.Preco_Unitario__c = newPrice;
            oli.Valor_unitario_original__c = newPrice;
            oli.Total_de_customizacao__c = oli.Quantity * newPrice;
        }else if(opp.Account.Escalao_Hidea__c != null){
            Decimal newPrice = (Decimal) pbe.get('Preco_' + opp.Account.Escalao_Hidea__c + '__c');
            oli.UnitPrice = newPrice;
            oli.Preco_Unitario__c = newPrice;
            oli.Valor_unitario_original__c = newPrice;
            oli.Total_de_customizacao__c = oli.Quantity * newPrice;
        }else{
            Decimal newPrice = c_AddProduct.calcPreco(pbe,oli.Quantity);
            oli.UnitPrice = newPrice;
            oli.Preco_Unitario__c = newPrice;
            oli.Valor_unitario_original__c = newPrice;
            oli.Total_de_customizacao__c = oli.Quantity * newPrice;
        }
    }

    
    public class SelectedProd{
        public boolean selected {get;set;}
        public OpportunityLineItem item {get;set;}
        
        public SelectedProd(boolean selected, OpportunityLineItem item){
            this.selected = selected;
            this.item = item;
        }
    }
    
    public class NovoProduto{
        public OpportunityLineItem oli;
        public List<OpportunityLineItem> customs;
        
        public NovoProduto(OpportunityLineItem oli){
            this.oli = oli;
            customs = new List<OpportunityLineItem>();
        }
    }
}