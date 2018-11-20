/* @Autor: Marco Galvão
 * @Ultima Modificação: Marco Galvão
 * Página acedida pelo site para iniciar o processo de criação de uma nova reclamação
 * @numCli : recebido por parametro URL "no" representa o numero do cliente que está a reclamar
 * @ftstamp : Stamp do ficheiro selecionado pelo utilizador; este stamp é passado entre componentes para que possam evocar os serviços de maneira correcta sempre para o mesmo registo PHC
 * @bostamp : Stamp do dossier selecionado pelo utilizador; este stamp é passado para o componente de linhas para que este possa filtrar caso tenha sido seleccionado um dossier;
 * @stage : fase em que a página se encontra. Valores possiveis são 1 e 2;
 * - stage = 1 : mostrar cmp_ChooseOrigin para escolha do documento financeiro base da reclamação
 * - stage = 2 : mostrar cmp_ChooseLines para escolha das linhas a reclamar
 * @linhas : Lista de documentos/dossiers a mostrar ao utilizador para selecionar um documento de base para a reclamação
 * @MAX_STAGE : fase máxima da página
 * */
public class c_NewClaim {
    //variaveis de url
    public String numCli {get;set;}
    public String token {get;set;}
    //acrescentar os restantes parametros--
    
    public String selectedLine {get;set;}
    public String ftstamp {get;set;}
    public String bostamp {get;set;}
    public Integer stage {get;set;}
    public List<UtilClaims.LinhasDoc> linhas {get;set;}
    public static final Integer MAX_STAGE = 2;
    public Account acc {get;set;}
    public String ficheiroEscolhido {get;set;}
    //variaveis de validação
    public boolean validClient {get;set;}
    public Token_Site__c tokenSite;
    public String lang {get;set;}
    
    public c_NewClaim(){
        stage = 1;
        numCli = ApexPages.currentPage().getParameters().get('no');
        token = ApexPages.currentPage().getParameters().get('token');
        lang = ApexPages.currentPage().getParameters().get('lang');
        List<Token_site__c> tokens = [SELECT Id, Token__c, Numero_de_cliente__c, Ip__c, Endereco_de_retorno__c, Data_de_entrada__c, Data_de_validade__c, Duracao__c, Validado__c
                                      FROM Token_Site__c
                                      Where Numero_de_cliente__c = :numCli];
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
            List<Account> accs = [Select Id,Name From Account Where numero_de_cliente__c = :numCli];
            if(!accs.isEmpty()) acc = accs.get(0);
        }
    }
    
    /* Avança entre componentes da página
     * recebe da página como parametros:
     * @ftstamp: Stamp do ficheiro escolhido pelo utilizador
     * @bostamp: Stamp do dossier escolhido pelo utilizador
     * */
    public void nextStage(){
        stage = stage < MAX_STAGE ? stage + 1 : stage;
        system.debug(selectedLine);
        UtilClaims.NewClaimLine aux = (UtilClaims.NewClaimLine) JSON.deserialize(selectedLine, UtilClaims.NewClaimLine.class);
        ficheiroEscolhido = aux.name + ' - ' + (aux.data_emissao != null ? aux.data_emissao.format('dd-MM-yyyy') : '');
        //chamar servico das linhas
        linhas = IntegratorClaims.getLines(aux.ftstamp, aux.bostamp);
    }
    
    public void backStage(){
        ficheiroEscolhido = null;
        stage = stage - 1;
    }

    public PageReference redirectFinal(){
        return new PageReference('/apex/p_ClaimsList?no=' + numCli + '&token=' +token);
    }
    
    public void checkPermaValidate(){
        if(validClient && tokenSite != null && !tokenSite.Validado__c){
            UtilClaims.permaValidateToken(tokenSite.Id);
        }
    }
}