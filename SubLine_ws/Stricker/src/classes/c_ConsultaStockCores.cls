public class c_ConsultaStockCores {
    public List<StockElement> elements {get;set;}
    
    private static final Datetime errorDate = Datetime.newInstance(1, 1, 1);
    
    public c_ConsultaStockCores(ApexPages.StandardController std){
        Product2 prod = [Select Id, Tamanho__c, Cor__c, ProductCode From Product2 Where Id = :std.getId()];
        elements = new List<StockElement>();
        if(prod.Cor__c != null && prod.Cor__c != ''){
            for(String cor : prod.Cor__c.split(';')){
                clientStricker.StockProduto result = integrator.servico.consultaStockProduto(prod.ProductCode, prod.Tamanho__c, cor);
                
                elements.add(new StockElement(result, cor));
            }
        }
    }
    
    public class StockElement{
        public OpportunityLineItem cor {get;set;}
        public Decimal stockAtual {get;set;}
        public Decimal stockCativo {get;set;}
        public Decimal stockDisponivel {get;set;}
        public Datetime dataPrevista {get;set;}
        public Decimal stockPrevisto {get;set;}
        
        public StockElement(clientStricker.StockProduto result, String cor){
            this.cor = new OpportunityLineItem();
            this.cor.Codigo_de_cor__c = cor;
            this.stockAtual = result.Stock_atual_xc;
            this.stockCativo = result.Stock_cativo_xc;
            stockDisponivel = result.Stock_atual_xc - Math.abs(result.Stock_cativo_xc);
            if(result.Stock_previsto_xc != errorDate){
                this.dataPrevista = result.Stock_previsto_xc;
                this.stockPrevisto = result.QTStock_previsto_xc;
            }
        }
    }
}