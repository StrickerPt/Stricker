public class c_PDFProForma {
	
    public Opportunity opp{get;set;}
    public Expedicao__c exp{get;set;}
    public Map<String,Product> produtos{get;set;}
    public String lang {get;set;}
    public List<Integer> numDoc {get;set;}
    public Map<Integer,String> descDoc {get;set;}
    public String currencySymbol {get;set;}
    public List<OpportunityLineItem> taxas {get;set;}
    
    public c_PDFProForma(ApexPages.StandardController controller){
        this.opp = [Select Id,Motivo_de_isencao_de_impostos__c,Incoterm__c,Amount,Account.Taxa_de_IVA__c,Account.Name,Referencia_interna__c,Account.Limite_de_credito_comercial__c,
                    Name,AccountId,Pricebook2Id,SyncedQuoteID,Type,StageName,Account.Numero_de_contribuinte__c,Account.Escalao_Hidea__c,Account.Numero_de_cliente__c,
                    Account.BillingStreet,Account.BillingPostalCode,Account.BillingCity,Account.BillingCountry,Account.Phone,Auto_Number__c,Validade__c,Pedido_por__r.Name,
                    CurrencyIsoCode From Opportunity Where Id = :controller.getId()];
        
        currencySymbol = Utils.currencySymbol(opp.CurrencyIsoCode);
        Map<String, String> reqParams = ApexPages.currentPage().getParameters(); 
    	lang = reqParams.get('lang');
        
        List<Expedicao__c> auxLista = [select id,Peso_da_expedicao__c,Volume_da_expedicao__c,Morada_aux__c,Transportadora__c,Observacoes_documento__c, Morada_de_entrega__r.Nome_da_empresa__c,Ao_cuidado_de__c,
                                       Morada_de_entrega__r.Morada_de_entrega__c,Morada_de_entrega__r.Codigo_postal__c,Morada_de_entrega__r.Localidade__c,Morada_de_entrega__r.Pais__c
                                       from Expedicao__c where Dossier__c =:opp.Id];
        if(!auxLista.isEmpty()){
            exp = auxLista[0];
        }
        numDoc = new List<Integer>();
        numDoc.add(1);
        numDoc.add(2);
        numDoc.add(3);
        descDoc = new Map<Integer,String>{1=>Label.Original,2=>Label.Duplicado,3=>Label.Triplicado};
        refreshProdutos();
    }
    
    public String getBanco(){
        if(opp != null){
            Map<String, Referencias_Bancarias__c> refBanco = Referencias_Bancarias__c.getAll();
            if(opp.CurrencyIsoCode == 'USD'){
                return refBanco.get('Millennium BCP').Banco__c;
            }else if(opp.Account.BillingCountry == 'España' || opp.Account.BillingCountry == 'Gibraltar'){
                return refBanco.get('Cuenta La Caixa').Banco__c;
            }else if(opp.Account.BillingCountry == 'France'){
                return refBanco.get('Banque BCP').Banco__c;
            }else if(opp.Account.BillingCountry == 'United Kingdom'){
                return refBanco.get('Santander Banking').Banco__c;
            }else if(opp.Account.BillingCountry == 'Poland'){
                return refBanco.get('Bank Zachodni WBK').Banco__c;
            }else{
                return refBanco.get('Millennium BCP').Banco__c;
            }
        }
        return '';
    }
    
    public void refreshProdutos(){
        this.produtos = new Map<String,Product>();
        this.taxas = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli :[select Id,Description,Product2.Name,Lingua_do_cliente__c,Preco_Unitario__c,Total_de_customizacao__c,Referencia_Relacionada__c,Tecnica__c ,Referencia_SKU__c,Product2Id,Dimensoes_maximas_de_impressao__c,Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,Codigo_de_cor__c,Componente_da_impressao__c,Desconto_unitario__c from OpportunityLineItem where OpportunityId=:opp.Id and Product2.RecordType.Name = 'Produto']){
            oli.Total_de_customizacao__c = oli.TotalPrice;
            oli.Preco_Unitario__c = oli.UnitPrice;
            Product aux = new Product(oli, oli.Product2Id);
            aux.idProduct = oli.Product2Id;
            aux.code = oli.ProductCode;
            this.produtos.put(oli.Id, aux);
        }
        for(OpportunityLineItem oli :[select Id,Description,Product2.Name,Lingua_do_cliente__c,Product2.Referencia_relacionada__c,Preco_Unitario__c,
                                      Total_de_customizacao__c,Referencia_Relacionada__c,Product2.Tecnica__c ,Referencia_SKU__c,
                                      Product2.Cores_de_customizacao__c,Product2Id,Dimensoes_maximas_de_impressao__c,Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,Codigo_de_cor__c,Product2.Componente_da_impressao__c,Desconto_unitario__c from OpportunityLineItem where OpportunityId=:opp.Id and Product2.RecordType.Name = 'Customização']){
            if(this.produtos.containsKey(oli.Referencia_Relacionada__c)){
                oli.Total_de_customizacao__c = oli.TotalPrice;
                oli.Preco_Unitario__c = oli.UnitPrice;
                Custom c = new Custom(oli);
                this.produtos.get(oli.Referencia_Relacionada__c).customList.put(oli.Product2Id,c);
            }
        }
        for(OpportunityLineItem tax : [Select Id,Description,Discount,Product2.Name,Lingua_do_cliente__c,Product2.Referencia_relacionada__c,Preco_Unitario__c,Total_de_customizacao__c,Referencia_Relacionada__c,Product2.Tecnica__c ,Referencia_SKU__c,Product2.Cores_de_customizacao__c,Product2Id,Dimensoes_maximas_de_impressao__c,Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,Codigo_de_cor__c,Product2.Componente_da_impressao__c,Desconto_unitario__c from opportunityLineItem Where OpportunityId=:opp.Id and Product2.RecordType.DeveloperName = 'Taxa']){
            taxas.add(tax);
        }
    }
    
    public String getPrazoEntrega(){
        Integer limiteCom = 0;
        if(opp.Account.Limite_de_credito_comercial__c != null){
            limiteCom = (Integer) opp.Account.Limite_de_credito_comercial__c;
        }
        return Date.today().addDays(limiteCom).format();
    }
    
    public Decimal getTotalIVA(){
        if(opp.Amount != null){
            if(opp.Account.Taxa_de_IVA__c != null && opp.Motivo_de_isencao_de_impostos__c == null){
                return ((opp.Amount * (1 + opp.Account.Taxa_de_IVA__c/100)) - opp.Amount).setScale(2, System.RoundingMode.CEILING);
            }else{
                return 0.00;
            }
        }
        return 0.00;
    }
    
    public Decimal getTotalEuro(){
        Decimal auxtotal = getTotalIVA();
        if(opp.Amount != null){
            return (opp.Amount + auxtotal).setScale(2, System.RoundingMode.CEILING);
        }
        return 0.00;
    }
    
    public Decimal getTotalEuroConverted(){
        Decimal auxtotal = getTotalIVAConverted();
        if(opp.Amount != null){
            Opportunity auxOpp =  [Select Id, convertCurrency(Amount) from Opportunity Where Id = :opp.Id];
            return (auxOpp.Amount + auxtotal).setScale(2, System.RoundingMode.CEILING);
        }
        return 0.00;
    }
    
    public Decimal getTotalIVAConverted(){
        if(opp.Amount != null){
            if(opp.Account.Taxa_de_IVA__c != null && opp.Motivo_de_isencao_de_impostos__c == null){
                Opportunity auxOpp =  [Select Id, convertCurrency(Amount) from Opportunity Where Id = :opp.Id];
                return ((opp.Amount * (1 + opp.Account.Taxa_de_IVA__c/100)) - opp.Amount).setScale(2, System.RoundingMode.CEILING);
            }else{
                return 0.00;
            }
        }
        return 0.00;
    }
    
    public Decimal getOppConvertedAmount(){
        Opportunity auxOpp =  [Select Id, convertCurrency(Amount) from Opportunity Where Id = :opp.Id];
        return auxOpp.Amount;
    }
    public class Product{
        public String idProduct{get;set;}
        public String code{get;set;}
        public Map<String,Custom> customList {get;set;}
        public OpportunityLineItem item {get;set;}
        public Product(OpportunityLineItem item,String idProduct){
            this.customList = new Map<String,Custom>();
            this.item = item;
            this.idProduct = idProduct;
        }
    }
    
    public class Custom{
        public OpportunityLineItem item {get;set;}
        public String description {get;set;}
        public Custom(OpportunityLineItem item){
            String auxCores = '';
            if(item.Product2.Cores_de_customizacao__c != null){
                auxCores = item.Product2.Cores_de_customizacao__c + ' ' + (Integer.valueOf(item.Product2.Cores_de_customizacao__c) < 1? 'cor' : 'cores');
            }
            this.item = item;
            this.description = item.Product2.Referencia_relacionada__c + ' - ' + item.Product2.Componente_da_impressao__c + ' - ' + item.Product2.Tecnica__c + (item.Dimensoes_maximas_de_impressao__c != null ? ' - ' + item.Dimensoes_maximas_de_impressao__c : '') + (auxCores != null ? ' - ' +auxCores : '');   
        }
    }
    
    public static String getCarimboUrl(){
        List<Document> lstDocument = [Select Id,Name,LastModifiedById from Document where DeveloperName = 'carimbo_striker' limit 1];
        if(!lstDocument.isEmpty()){
            string strDocUrl = URL.getSalesforceBaseUrl().getProtocol() + '://c.' +
                URL.getSalesforceBaseUrl().getHost().split('\\.')[1] + '.content.force.com' + '/servlet/servlet.FileDownload?file=' + lstDocument[0].Id;
            return strDocUrl;
        }
        return '';
    }
    
    public static String getPMELiderUrl(){
        List<Document> lstDocument = [Select Id,Name,LastModifiedById from Document where DeveloperName = 'PME_lider' limit 1];
        if(!lstDocument.isEmpty()){
            string strDocUrl = URL.getSalesforceBaseUrl().getProtocol() + '://c.' +
                URL.getSalesforceBaseUrl().getHost().split('\\.')[1] + '.content.force.com' + '/servlet/servlet.FileDownload?file=' + lstDocument[0].Id;
            return strDocUrl;
        }
        return '';
    }
    
    public static String getLogoISOUrl(){
        List<Document> lstDocument = [Select Id,Name,LastModifiedById from Document where DeveloperName = 'logo_iso_9001' limit 1];
        if(!lstDocument.isEmpty()){
            string strDocUrl = URL.getSalesforceBaseUrl().getProtocol() + '://c.' +
                URL.getSalesforceBaseUrl().getHost().split('\\.')[1] + '.content.force.com' + '/servlet/servlet.FileDownload?file=' + lstDocument[0].Id;
            return strDocUrl;
        }
        return '';
    }
    
    public static String getLogoUrl(){
        List<Document> lstDocument = [Select Id,Name,LastModifiedById from Document where DeveloperName = 'Logo' limit 1];
        if(!lstDocument.isEmpty()){
            string strOrgId = UserInfo.getOrganizationId();
            string orgInst = URL.getSalesforceBaseUrl().getHost();
            orgInst = orgInst.substring(0, orgInst.indexOf('.')) + '.content.force.com';
            string strDocUrl = URL.getSalesforceBaseUrl().getProtocol() + '://c.' +
                orgInst + '/servlet/servlet.ImageServer?id=' + lstDocument[0].Id + '&oid=' + strOrgId;
            return strDocUrl;
        }
        return '';
    }
}