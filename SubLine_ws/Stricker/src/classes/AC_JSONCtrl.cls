public class AC_JSONCtrl {
    //whereClause="IsActive = true"
    public String getJSON(){
        List<DataWrapper> wrp = new List<DataWrapper>();
        
        //get params from url
        String searchTerm = Apexpages.currentPage().getParameters().get('q');
        String objName = Apexpages.currentPage().getParameters().get('obj');
        List<String> lstFields = new List<String>();
        String label = Apexpages.currentPage().getParameters().get('label');
        lstFields.add(label);
        String urlDetail = Apexpages.currentPage().getParameters().get('detail');
        String urlWhere = ApexPages.currentPage().getParameters().get('wc');
        if(urlWhere != null && urlWhere != ''){
            urlWhere = EncodingUtil.urlDecode(urlWhere,'utf-8').trim();
            urlWhere = urlWhere.unescapeHtml4();
            if(urlWhere.startsWith('and')){
                urlWhere = urlWhere.substring(3);
            }
        }
        String urlLimit = ApexPages.currentPage().getParameters().get('lm');
        if(urlLimit == null || urlLimit == ''){
            urlLimit = '10';
        }
        
        //add comma-separated detail fields to query and store in separate list for retrieve
        List<String> lstDetail = new List<String>();
        if(urlDetail!= null && urlDetail != ''){
            lstDetail = urlDetail.split(',');
            lstFields.addAll(lstDetail);
        }
        String value = Apexpages.currentPage().getParameters().get('value');
        lstFields.add(value);
        
        //start building query
        String qry = 'Select ';
        List<String> fieldQry = new List<String>();
        for(String s :lstFields){
            fieldQry.add(s);
        }
        qry += String.join(fieldQry,',');
        //qry += ', Product2.Nome_para_user__c';
        //search by every field in the label input separated by comma
        string likeCondition = '(';
        boolean isFirst = true;
        for(String s: label.split(',')){
            likeCondition += (!isFirst ? ' Or' : '') + ' ' + s + ' like \'%' + searchTerm + '%\' ';
            if(isFirst){
                isFirst = false;
            }
        }
        for(String s: lstDetail){
            likeCondition += (!isFirst ? ' Or' : '') + ' ' + s + ' like \'%' + searchTerm + '%\' ';
            if(isFirst){
                isFirst = false;
            }
        }
        likeCondition += ')';
        qry += qry.contains('Name') ? '' : ' ,Name';
        qry += ' from ' + objName + ' where ' + likeCondition + (objName == 'PricebookEntry' ? ' and Product2.RecordType.Name = \'Produto\'':'');
        if(urlWhere != null && urlWhere != ''){
            qry += ' and ' + urlWhere;
        }
        
        qry+= ' Limit ' + urlLimit;
        System.debug('====>> qry : ' + qry);
        
        //loop through records to get data
        for(SObject o :Database.query(qry)){
            String thisdetail ='';
            
            //since multiple details fields can exist, loop through and store data in list
            //then convert list to comma-separated string for display
            if(urlDetail != null && urlDetail != ''){
                if(lstDetail.size() > 1){
                    List<String> dlist = new List<String>();
                    for(String d :lstDetail){
                        system.debug(d);
                        if(d.contains('.')){
                            dlist.add((String) o.getSObject(d.split('\\.')[0]).get(d.split('\\.')[1]));
                        }else{
                            dlist.add((String)o.get(d));
                        }
                    }
                    thisdetail = String.join(dlist,', ');
                }
                else{
                    thisdetail = (String) o.get(lstDetail[0]);
                }
            }
            
            //show label in the correct order without null values
            String lab = '';
            
            for(String s:label.split(',')){
                system.debug(s);
                system.debug(s.split('\\.'));
                if(s.split('.').size()>1){
                    system.debug(o.getSObject(s.split('.')[0])); 
                    system.debug(o.getSObject(s.split('.')[0]).get(s.split('.')[1]));
                }
                //catching references through lookup fields
                lab += s.split('\\.').size() > 1 ? (String)(o.getSObject(s.split('\\.')[0]).get(s.split('\\.')[1])): (String)o.get(s);
                lab +=  ' ';
            }
            lab = lab.removeEnd(' ');
            lab = lab.replace( ' null', '');
            lab = lab.replace( 'null ', '');
            
            String nome = (objName == 'PricebookEntry' ? ((String) o.getSObject('Product2').get('Nome_para_user__c')) : null);
            wrp.add(new DataWrapper(lab, thisdetail, ((String)o.get(value)), nome != null ? nome : (String)o.get('Name')));
        }
        
        return JSON.serialize(wrp);
    }
    
    public class DataWrapper{
        String label, detail, value, name;
        
        public DataWrapper(String l, String d, String v, String n){
            label = l; //label of suggestion
            detail = d; //detail of suggestion
            value = v; //the value of what is stored in the input tag. Commonly the Id of the record
            name = n;
        }
    }
}