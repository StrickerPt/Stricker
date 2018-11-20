public class c_ClaimFromClient {
    public String numCli {get;set;}
    public String selectedLine {get;set;}
    public String ftstamp {get;set;}
    public String bostamp {get;set;}
    public Integer stage {get;set;}
    public List<UtilClaims.LinhasDoc> linhas {get;set;}
    public static final Integer MAX_STAGE = 2;
    public Account acc {get;set;}
    public Case caso {get;set;}
    public String ficheiroEscolhido {get;set;}
    public List<Account> filteredList {get;set;}
    public String filter {get;set;}
    
    public c_ClaimFromClient(ApexPages.StandardController std){
        stage = 1;
        filteredList = new List<Account>();
        //applyFilter();
        caso = (Case) std.getRecord();
        if(caso.AccountId != null){
            numCli = [Select Id, Numero_de_Cliente__c From Account Where Id = :caso.AccountId].Numero_de_Cliente__c;
            acc = [Select Id,Name From Account Where Numero_de_Cliente__c = :numCli];
        }
       
    }
    
    /* Avança entre componentes da página
    * recebe da página como parametros:
    * @ftstamp: Stamp do ficheiro escolhido pelo utilizador
    * @bostamp: Stamp do dossier escolhido pelo utilizador
    * */
    public void nextStage(){
        stage = stage < MAX_STAGE ? stage + 1 : stage;
        UtilClaims.NewClaimLine aux = (UtilClaims.NewClaimLine) JSON.deserialize(selectedLine, UtilClaims.NewClaimLine.class);
        ficheiroEscolhido = aux.name + ' - ' + (aux.data_emissao != null ? aux.data_emissao.format('dd-MM-yyyy') : '01-01-1900');
        //chamar servico das linhas
        linhas = IntegratorClaims.getLines(aux.ftstamp, aux.bostamp);
    }
    
    public void backStage(){
        ficheiroEscolhido = null;
        stage = stage - 1;
    }
    
    public void applyFilter(){
        filteredList.clear();
        
        if(filter != null && filter != ''){
            String aux = '%' + filter + '%';
            String query = 'Select id, Name, Numero_de_cliente__c from Account Where Name Like \''+ aux + '\' Or Numero_de_cliente__c Like \'' + aux +'\' Limit 5';
            filteredList = Database.query(query);
        }
    }
    public void setAccount(){
        if(numCli != null && numCli != ''){
            acc = [Select Id,Name From Account Where Numero_de_Cliente__c = :numCli];
        }
    }
    public void confirmNumCLi(){
        acc = [Select Id,Name From Account Where Numero_de_Cliente__c = :numCli];
    }
}