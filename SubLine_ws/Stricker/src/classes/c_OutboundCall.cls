public class c_OutboundCall {
    public String ContaID{get;set;}
    public String userLang {get;set;}
    public c_OutboundCall(ApexPages.StandardController controller) {
        this.ContaID = controller.getId();
        userLang = UserInfo.getLanguage();
    }
}