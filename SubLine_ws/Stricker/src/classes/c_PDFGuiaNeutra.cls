public class c_PDFGuiaNeutra {
	
    public Expedicao__c expedicao {get;set;}
    public Map<String,Product> produtos{get;set;}
    public String lang {get;set;}
    
    public c_PDFGuiaNeutra(ApexPages.StandardController controller){
        this.expedicao = (Expedicao__c)controller.getRecord();
        this.expedicao = [select id,Transportadora__c,N_de_expedicao__c,Numero_de_volumes__c,Peso_da_expedicao__c,Morada_de_entrega__r.Telefone_logistico__c,Morada_de_entrega__r.MSEQ__c,
                          Morada_de_entrega__r.Morada_de_entrega__c,Morada_de_entrega__r.Codigo_postal__c,Morada_de_entrega__r.Localidade__c,Dossier__c,Dossier__r.Auto_Number__c,
                          Dossier__r.Account.Name,Dossier__r.Account.BillingStreet,Dossier__r.Account.BillingPostalCode,Dossier__r.Account.BillingCountry,
                          Dossier__r.Account.Numero_de_contribuinte__c,Dossier__r.Account.Numero_de_cliente__c,Dossier__r.Pedido_por__r.Name
                          from Expedicao__c where Id =:controller.getId()];
        
        Map<String, String> reqParams = ApexPages.currentPage().getParameters(); 
    	lang = reqParams.get('lang');
        
        refreshProdutos();
    }
    
    public void refreshProdutos(){
        this.produtos = new Map<String,Product>();
        for(OpportunityLineItem oli :[select Id,Description,Product2.Name,Preco_Unitario__c,Lingua_do_cliente__c,Peso__c,Total_de_customizacao__c,Referencia_Relacionada__c,Tecnica__c ,Referencia_SKU__c,Product2Id,Dimensoes_maximas_de_impressao__c,Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,Codigo_de_cor__c,Componente_da_impressao__c,Desconto_unitario__c from OpportunityLineItem where OpportunityId=:expedicao.Dossier__c and Product2.RecordType.Name = 'Produto']){
            oli.Total_de_customizacao__c = oli.TotalPrice;
            oli.Preco_Unitario__c = oli.UnitPrice;
            Product aux = new Product(oli, oli.Product2Id);
            aux.idProduct = oli.Product2Id;
            aux.code = oli.ProductCode;
            this.produtos.put(oli.Id, aux);
        }
        for(OpportunityLineItem oli :[select Id,Description,Product2.Name,Product2.Referencia_relacionada__c,Lingua_do_cliente__c,Peso__c,Preco_Unitario__c,Total_de_customizacao__c,Referencia_Relacionada__c,Product2.Tecnica__c ,Referencia_SKU__c,Product2.Cores_de_customizacao__c,Product2Id,Dimensoes_maximas_de_impressao__c,Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,Codigo_de_cor__c,Product2.Componente_da_impressao__c,Desconto_unitario__c from OpportunityLineItem where OpportunityId=:expedicao.Dossier__c and Product2.RecordType.Name = 'Customização']){
            if(this.produtos.containsKey(oli.Referencia_Relacionada__c)){
                oli.Total_de_customizacao__c = oli.TotalPrice;
                oli.Preco_Unitario__c = oli.UnitPrice;
                Custom c = new Custom(oli);
                this.produtos.get(oli.Referencia_Relacionada__c).customList.put(oli.Product2Id,c);
            }
        }
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
}