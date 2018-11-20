public class c_PDFOpportunity {
	public Opportunity opp{get;set;}
    public Map<String,Product> produtos{get;set;}
    public Map<String, MapExpProd> prodMap {get;set;}
    public String lang {get;set;}
    public Map<String,Product> transportadoras{get;set;}
    
    public Map<String,Product> taxas {get;set;}
    
    public c_PDFOpportunity(ApexPages.StandardController controller){
        
        this.opp = [Select Id,Motivo_de_isencao_de_impostos__c,Incoterm__c,Amount,Account.Taxa_de_IVA__c,Account.Name,Referencia_interna__c,Account.Limite_de_credito_comercial__c,
                    Name,AccountId,Pricebook2Id,SyncedQuoteID,Type,StageName,Account.Numero_de_contribuinte__c,Account.Escalao_Hidea__c,Account.Numero_de_cliente__c,
                    Account.BillingStreet,Account.BillingPostalCode,Account.BillingCity,Account.BillingCountry,Account.Phone,Auto_Number__c,Validade__c,Pedido_por__r.Name,
                    CurrencyIsoCode From Opportunity Where Id = :controller.getId()];
        
        Map<String, String> reqParams = ApexPages.currentPage().getParameters(); 
    	lang = reqParams.get('lang');
        
        refreshProdutos();
        prodMap = new Map<String, MapExpProd>();
        for(String key : produtos.keySet()){
            Product prod = produtos.get(key);
            if(!prodMap.containsKey(prod.item.Expedicao__c)) prodMap.put(prod.item.Expedicao__c, new MapExpProd(prod.item.Expedicao__r));
            prodMap.get(prod.item.Expedicao__c).oliIds.add(key);
        }
        for(String key : transportadoras.keySet()){
            Product prod = transportadoras.get(key);
            prodMap.get(prod.item.Expedicao__c).linhaPortes = key;
        }
    }
    
    public void refreshProdutos(){
        this.produtos = new Map<String,Product>();
        for(OpportunityLineItem oli :[select Id,Description,Product2.Name,Lingua_do_cliente__c,Preco_Unitario__c,Total_de_customizacao__c,
                                      Referencia_Relacionada__c,Tecnica__c ,Referencia_SKU__c,Product2Id,Dimensoes_maximas_de_impressao__c,
                                      Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,
                                      Codigo_de_cor__c,Componente_da_impressao__c,Desconto_unitario__c, Expedicao__c
                                      from OpportunityLineItem where OpportunityId=:opp.Id and Product2.RecordType.Name = 'Produto']){
            oli.Total_de_customizacao__c = oli.TotalPrice;
            oli.Preco_Unitario__c = oli.UnitPrice;
            Product aux = new Product(oli, oli.Product2Id);
            aux.idProduct = oli.Product2Id;
            aux.code = oli.ProductCode;
            this.produtos.put(oli.Id, aux);
        }
        for(OpportunityLineItem oli :[select Id,Description,Product2.Name,Lingua_do_cliente__c,Product2.Referencia_relacionada__c,Preco_Unitario__c,Total_de_customizacao__c,Referencia_Relacionada__c,Product2.Tecnica__c ,Referencia_SKU__c,Product2.Cores_de_customizacao__c,Product2Id,Dimensoes_maximas_de_impressao__c,Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,Codigo_de_cor__c,Product2.Componente_da_impressao__c,Desconto_unitario__c from OpportunityLineItem where OpportunityId=:opp.Id and Product2.RecordType.Name = 'Customização']){
            if(this.produtos.containsKey(oli.Referencia_Relacionada__c)){
                oli.Total_de_customizacao__c = oli.TotalPrice;
                oli.Preco_Unitario__c = oli.UnitPrice;
                Custom c = new Custom(oli);
                this.produtos.get(oli.Referencia_Relacionada__c).customList.put(oli.Product2Id,c);
            }
        } 

        this.transportadoras = new Map<String,Product>();
        for(OpportunityLineItem oli :[select Id,Description,Product2.Name,Lingua_do_cliente__c,Preco_Unitario__c,Total_de_customizacao__c,
                                      Referencia_Relacionada__c,Tecnica__c ,Referencia_SKU__c,Product2Id,Dimensoes_maximas_de_impressao__c,
                                      Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,
                                      Codigo_de_cor__c,Componente_da_impressao__c,Desconto_unitario__c, Expedicao__c
                                      from OpportunityLineItem where OpportunityId=:opp.Id and ProductCode In :c_AddProduct.transpCodes]){
            transportadoras.put(oli.Id, new Product(oli, oli.Id));
        }
        
        this.taxas = new Map<String,Product>();
        for(OpportunityLineItem oli :[select Id,Description,Product2.Name,Lingua_do_cliente__c,Preco_Unitario__c,Total_de_customizacao__c,Referencia_Relacionada__c,Tecnica__c ,Referencia_SKU__c,Product2Id,Dimensoes_maximas_de_impressao__c,Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,Codigo_de_cor__c,Componente_da_impressao__c,Desconto_unitario__c from OpportunityLineItem where OpportunityId=:opp.Id and ProductCode Not In :c_AddProduct.transpCodes and Product2.RecordType.Name = 'Taxa']){
            taxas.put(oli.Id, new Product(oli, oli.Id));
        }
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
    
    public static String getLogoISOUrl(){
        List<Document> lstDocument = [Select Id,Name,LastModifiedById from Document where DeveloperName = 'logo_iso_9001' limit 1];
        if(!lstDocument.isEmpty()){
            string strDocUrl = URL.getSalesforceBaseUrl().getProtocol() + '://c.' +
                URL.getSalesforceBaseUrl().getHost().split('\\.')[1] + '.content.force.com' + '/servlet/servlet.FileDownload?file=' + lstDocument[0].Id;
            return strDocUrl;
        }
        return '';
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
            this.item = item;
            this.description = item.Product2.Referencia_relacionada__c + ' - ' + item.Product2.Componente_da_impressao__c + ' - ' + item.Product2.Tecnica__c + ' - ' + item.Dimensoes_maximas_de_impressao__c + ' - ' + item.Product2.Cores_de_customizacao__c;   
        }
    }
    
    public class MapExpProd{
        public Expedicao__c exp {get;set;}
        public String linhaPortes {get;set;}
        public List<String> oliIds {get;set;}
        
        public MapExpProd(Expedicao__c exp){
            this.exp = exp;
            //this.oliIds = oliIds;
            oliIds = new List<String>();
        }
    }
}