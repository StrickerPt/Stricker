public class b_DocumentosFinanceirosUK implements Database.Batchable<Integer>,Database.AllowsCallouts{
    
    //método que define quantos lotes corre no processo
    public List<Integer> start(Database.BatchableContext BC){
        try{
            Integrator.servico.timeout_x = 120000;
            
            //chama primeira pagina ara saber numero total de paginas
            clientStricker.ListaDocsFinanceirosPHC resultado = Integrator.servico.lstDocFinanceirosBD(1, 'UK');

            List<Integer> pages = new List<Integer>();
            for(Integer i = 1; i <= resultado.numtotalPaginas ; i++){
                pages.add(i);
            }
            
            return pages;
        }catch(Exception ex){
            system.debug(ex.getMessage() + ex.getLineNumber());
            return new List<Integer>();
        }
    }
    
    //executa uma iteração do total de paginas a chamar
    public void execute(Database.BatchableContext BC, List<Integer> scope){
        Integrator.servico.timeout_x = 120000;
        //chamar serviço e tratar dados

        List<clientStricker.ListaDocsFinanceirosPHC> results = new List<clientStricker.ListaDocsFinanceirosPHC>();
        for(Integer pagina : scope){
            try{
                clientStricker.ListaDocsFinanceirosPHC result = Integrator.servico.lstDocFinanceirosBD(pagina, 'UK');
                
                results.add(result);
            }catch(Exception ex){
                UtilClaims.sendEmailFailure('Falha documentos financeiros UK', ex.getMessage() + ' ' + ex.getLineNumber() + ' \r\n Na página ' + pagina);
            }
        }
        
        if(!results.isEmpty()){
            UtilDocFin.treatDocs(results);
        }
    }
    
    //executa no final de todos os lotes terem corrido
    public void finish(Database.BatchableContext BC){}
}