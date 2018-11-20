public class c_ClaimsList {
    public String no {get;set;}
    public String token {get;set;}
    //acrescentar os restantes parametros--
    
    public Account acc {get;set;}
    public List<Case> openCases {get;set;}
    public List<Case> closedCases {get;set;}
    
    public boolean validClient {get;set;}
    public Token_Site__c tokenSite;
    
    public c_ClaimsList(){
        no = ApexPages.currentPage().getParameters().get('no');
        token = ApexPages.currentPage().getParameters().get('token');
        //acrescentar os restantes parametros--
        List<Token_site__c> tokens = [SELECT Id, Token__c, Numero_de_cliente__c, Ip__c, Endereco_de_retorno__c, Data_de_entrada__c, Data_de_validade__c, Duracao__c, Validado__c
                                      FROM Token_Site__c
                                      Where Numero_de_cliente__c = :no];
        if(tokens.isEmpty()){
            validClient = false;
        }else{
            for(Token_site__c tok : tokens){
                validClient = UtilClaims.validateToken(token, tok);
                
                if(validClient) {
                    tokenSite = tok;
                    break;
                }
            }
        }
        if(validClient){
            try{
                acc = [Select Id, Name, Numero_de_cliente__c From Account Where Numero_de_cliente__c = :no];
                openCases = [Select id, CaseNumber, CreatedDate, Status from Case Where account.numero_de_cliente__c = :no And IsClosed = false order by createdDate desc];
                Claim_Config__mdt conf = [Select Id, Visualizar_reclamacoes_fechadas__c from Claim_Config__mdt Where DeveloperName = 'Claims_Config_1'];
                closedCases = [Select id, CaseNumber, CreatedDate, Status from Case 
                               Where account.numero_de_cliente__c = :no And
                               IsClosed = true And
                               ClosedDate > :System.today().addDays((Integer) conf.Visualizar_reclamacoes_fechadas__c)
                               order by createdDate desc];
            }catch(Exception ex){
                acc = new Account();
                openCases = new List<Case>();
                closedCases = new List<Case>();
            }
        }
    }
    
    public Double offset{get{
        TimeZone tz = UserInfo.getTimeZone();
        //Milliseconds to Day
        return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }}
    
    public void checkPermaValidate(){
        if(validClient && tokenSite != null && !tokenSite.Validado__c){
            UtilClaims.permaValidateToken(tokenSite.Id);
        }
    }
}