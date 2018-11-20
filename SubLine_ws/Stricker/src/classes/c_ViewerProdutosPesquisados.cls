public class c_ViewerProdutosPesquisados {
    
    public List<SearchedProds> prods {get;set;}
    public Map<Decimal,TableRow> datas {get;set;}
    public Account acc;
    public c_ViewerProdutosPesquisados(ApexPages.StandardController stdCtrl){
        this.acc = [select Id,Numero_de_cliente__c from Account where Id = :stdCtrl.getId()];
        datas = new Map<Decimal,TableRow>();
    }
    
    public void init(){
        prods = IntegratorSite.consultaProdsPesquisados(Integer.valueOf(acc.Numero_de_cliente__c));
        for(SearchedProds prod : prods){
            if(!datas.containsKey(prod.ref)){
                datas.put(prod.ref, new TableRow(prod.ref));
            }
            datas.get(prod.ref).counter += 1;
            string aux = '';
            if(datas.get(prod.ref).datas.size() != 0){
                aux += '| ';
            }
            aux += prod.dates.date().format();
            datas.get(prod.ref).datas.add(aux);
        }
    }
    
    public class SearchedProds{
        public Decimal ref {get;set;}
        public Datetime dates {get;set;}
        
        public SearchedProds(Decimal ref, Datetime data){
            this.ref = ref;
            this.dates = data;
        }
    }
    
    public class TableRow{
        public Decimal ref {get;set;}
        public Integer counter {get;set;}
        public List<String> datas {get;set;}
        
        public TableRow(Decimal ref){
            this.ref = ref;
            counter = 0;
            datas = new List<String>();
        }
    }
}