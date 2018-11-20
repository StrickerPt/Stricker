public class IntegratorSite {
    
    public static clientStrickerSite.sitePStrickerSalesSoap servico = new clientStrickerSite.sitePStrickerSalesSoap();
    public static List<c_ViewerOnlineUsers.ViewerLogIn> onlineHistory(Long nCliente){
        List<c_ViewerOnlineUsers.ViewerLogIn> linhas = new List<c_ViewerOnlineUsers.ViewerLogIn>();
        try{
            servico.timeout_x = 120000;
            clientStrickerSite.ArrayOfViewerLogins result = servico.lstCountLoginsByCliente(nCliente);
            
            if(result.viewerLogins != null){
                for(clientStrickerSite.viewerLogins viewerLog : result.viewerLogins){
                    linhas.add(new c_ViewerOnlineUsers.ViewerLogIn(viewerLog));
                }
            }
        }catch(Exception ex){}
        
        return linhas;
    }
    
    public static List<c_ViewerUtilizadores.Utilizador> consultaUtilizadores(Integer nCliente){
        List<c_ViewerUtilizadores.Utilizador> users = new List<c_ViewerUtilizadores.Utilizador>();
        clientStrickerSite.ArrayOfViewerClienteUtilizadores result = new clientStrickerSite.sitePStrickerSalesSoap().lstUtilizadoresByCliente(nCliente);
        
        if(result.viewerClienteUtilizadores != null){
            for(clientStrickerSite.viewerClienteUtilizadores user : result.viewerClienteUtilizadores){
                users.add(new c_ViewerUtilizadores.Utilizador(user.idClienteERP, user.clienteUsername,user.clienteEmail,user.activo,user.podeEncomendar));
            }
        }
        return users;
    }
    
    public static List<c_ViewerProdutosPesquisados.SearchedProds> consultaProdsPesquisados(Integer nCliente){
        List<c_ViewerProdutosPesquisados.SearchedProds> sProds = new List<c_ViewerProdutosPesquisados.SearchedProds>();
        clientStrickerSite.ArrayOfViewerPesqProdutos result = new clientStrickerSite.sitePStrickerSalesSoap().lstPesquisaProdutosByCliente(nCliente);
        
        if(result.viewerPesqProdutos != null){
            for(clientStrickerSite.viewerPesqProdutos prod : result.viewerPesqProdutos){
                sProds.add(new c_ViewerProdutosPesquisados.SearchedProds(prod.idProdutoERP, prod.dataPesquisa));
            }
        }
        return sProds;
    }
    
    public static boolean resetPassword(String username, String password){
        return new clientStrickerSite.sitePStrickerSalesSoap().resetPassword(username, password);
    }
    
    public static boolean disableUser(String username){
        return new clientStrickerSite.sitePStrickerSalesSoap().disableUser(username);
    }
    
    public static clientStrickerSite.stampUpSet createSiteUser(clientStrickerSite.ClienteUserToSite newUser){
        return new clientStrickerSite.sitePStrickerSalesSoap().criaUserWeb(newUser);
    }
}