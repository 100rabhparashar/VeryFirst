//Editing for source tree
global class OrderSearch {
    
    public static Boolean isSandbox;
    static {
        isSandbox = [SELECT Id, isSandbox FROM Organization].isSandbox;
    }
    
    @AuraEnabled
    global static list<Account> fetchData(String accName){
        List<Account> accList=new List<Account>();
        String query='';
        String temp=accName +'%';
        query='Select bdmd_CR_Party_ID__c,Name from Account where Name LIKE : temp';
        accList=database.query(query);
        return accList;
    }

    public static String Nu;
    @AuraEnabled
    global static String getEntitlement(String OrderId){
        bdmd_api_logger.StartTime = Datetime.now();
        List<SearchWrapper> wrapperList = new List<SearchWrapper>();
        List<bdmd_CustomerSSOT_Constants__mdt> listItems = [SELECT Id, Name__c, Prod__c, Sandbox__c FROM bdmd_CustomerSSOT_Constants__mdt];
        Map<String,String> ciscoMetadatMap = new Map<String,String>(); 
        for(bdmd_CustomerSSOT_Constants__mdt metaData : listItems){
            if(isSandbox){
                ciscoMetadatMap.put(metaData.Name__c,metaData.Sandbox__c);                
            }else{
                ciscoMetadatMap.put(metaData.Name__c,metaData.Prod__c);
            }            
        }
        System.debug('ciscoMetadatMap@@@ '+ciscoMetadatMap);
        String endpoint = ciscoMetadatMap.get('Entitlement Token Fetch');
        String apirequest=ciscoMetadatMap.get('Entitlement Fetch'); 
        apirequest+=OrderId;
        System.debug('URL@@@ '+apirequest);
        String Method='POST';
        String body=ciscoMetadatMap.get('Body');
        System.debug('Body@@@ '+body);
        String token=ciscoMetadatMap.get('Token');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apirequest);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Authorization', 'Bearer ' + bdmd_CustomerSSOT_API.getToken(Method,endpoint,body,token));
        HttpResponse response = http.send(request);
        List<EntitlementWrapper> listEntitlement = EntitlementWrapper.parse(response.getBody());
        List<String> l2=new List<string>();
        
        Integer Assigned=0;
        Integer Used=0;
        Integer Entitles=0;
        Integer nu;
        for(EntitlementWrapper ew:listEntitlement){
            	
                SearchWrapper wrapper = new SearchWrapper();
                wrapper.Name = ew.user.first_name+' '+ew.user.last_name;
            	wrapper.Email = ew.user.email_id;
            	wrapper.Start_date=ew.start_date.substring(0,10);
            	wrapper.End_date=ew.end_date.substring(0,10);
            	if(ew.Status.name=='ENTITLED'){
            		Entitles++;
            	}
            	wrapper.No_Entitles=String.valueOf(Entitles);
            	wrapper.No_Assigned=String.valueOf(Assigned);
            	wrapper.No_Used=String.valueOf(wrapperList.size());
                wrapper.Status=ew.Status.name;
            	nu=Entitles;
            	wrapper.nu=String.valueOf(nu);
            	wrapperList.add(wrapper);
                system.debug('nu###'+nu);
            
        }
        system.debug('outside for loop nu###'+nu);
        System.debug('List Size### '+wrapperList.size());
       // Nu=String.valueOf(wrapperList.size());
        System.debug('Nu#######'+Nu);
        System.debug('List of entitlement is #### '+wrapperList);
        // Logger call
        bdmd_api_logger.APIServiceName = 'Entitlement API';
        bdmd_api_logger.RequestURL = apirequest;
        bdmd_api_logger.Status = response.getStatus();
        bdmd_api_logger.StatusCode = String.valueOf(response.getStatusCode());
        //bdmd_api_logger.Message =  Status;
        //bdmd_api_logger.RequestBody = jsonbody;
        bdmd_api_logger.ResponseBody = response.getBody();        
        bdmd_api_logger.EndTime = Datetime.now();
        BDMD_API_Logger.saveLog();
        return JSON.serialize(wrapperList);
    }
    public Class SearchWrapper{
        @AuraEnabled
        public string Name{get;set;}
        @AuraEnabled
        public string Email{get;set;}
         @AuraEnabled
        public string Start_date{get;set;}
        @AuraEnabled
        public string End_date{get;set;}
        @AuraEnabled
        public string No_Entitles{get;set;}
        @AuraEnabled
        public string No_Assigned{get;set;}
        @AuraEnabled
        public string No_Used{get;set;}
        @AuraEnabled
        public String Status{get;set;}
        public string nu{get;set;}
        
        
    }
    @AuraEnabled
    global static Map<String,List<String>> returnOrder(String SearchItem,Integer searchByFlag){
        
        
        //System.debug('Search@@@@'+SearchItem);
        //String o=getEntitlement('7ae99f16-1122-11ec-9326-42a77c4393db');
       // system.debug('Nu #### '+Nu);
        List<bdmd_CustomerSSOT_Constants__mdt> listItems = [SELECT Id, Name__c, Prod__c, Sandbox__c FROM bdmd_CustomerSSOT_Constants__mdt];
        Map<String,String> ciscoMetadatMap = new Map<String,String>(); 
        for(bdmd_CustomerSSOT_Constants__mdt metaData : listItems){
            if(isSandbox){
                ciscoMetadatMap.put(metaData.Name__c,metaData.Sandbox__c);                
            }else{
                ciscoMetadatMap.put(metaData.Name__c,metaData.Prod__c);
            }            
        }
        String endpoint = ciscoMetadatMap.get('Token Fetch');
        String apirequest='';
        if(searchByFlag==3){
            apirequest=ciscoMetadatMap.get('FetchOrder');
        	apirequest+='customer_id='+SearchItem;
        }
        else if(searchByFlag==1){
            apirequest=ciscoMetadatMap.get('FetchOrderNumber');
        	apirequest+='order_number='+SearchItem;
        }
        else if(searchByFlag==2){
            system.debug('--Acc>  '+SearchItem);
            List<Account> l2=new List<Account>();
            l2=fetchData(SearchItem);
            SearchItem=l2[0].bdmd_CR_Party_ID__c;
            apirequest=ciscoMetadatMap.get('FetchOrder');
        	apirequest+='customer_id='+SearchItem;
        }
        System.debug('URL@@@ '+apirequest);
        String Method='POST';
        String body=ciscoMetadatMap.get('Body');
        //System.debug('Body@@@ '+body);
        String token=ciscoMetadatMap.get('Token');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apirequest);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Authorization', 'Bearer ' + bdmd_CustomerSSOT_API.getToken(Method,endpoint,body,token));
        HttpResponse response = http.send(request);
        DataWrapper d=new DataWrapper();
        system.debug('======>>>>>'+response.getBody());
         List<DataWrapper> myJSONList= DataWrapper.parse(response.getBody()); 
       // List<Opportunity>oppList=[Select ID,LCMT_Status__c,Opportunity_Number__c from Opportunity];
        Set<string>ordernumberSet=new Set<String>();
        
            for(DataWrapper dw1:myJSONList){
                ordernumberSet.add(dw1.order_number);
            }
        List<Opportunity> opps=new List<Opportunity>();
        if(ordernumberSet!=null)
        {
			
                        opps=[Select ID,LCMT_Status__c,Opportunity_Number__c from Opportunity where Opportunity_Number__c =:ordernumberSet];

        }
        //System.debug('Body@@@11 '+response.getBody());
        Map<String,List<String>> m1=new Map<String,List<String>>();
        Map<String,Opportunity> mapOpportunity=new Map<String,Opportunity>();
        System.debug('List is this :' + myJSONList);
        //System.debug('Order Line Items '+ myJSONList.order_line_items{});
        //for(Opportunity opp:oppList){
        for(Opportunity opp:opps){
            mapOpportunity.put(opp.Opportunity_Number__c, opp);
        }
        for(DataWrapper dw:myJSONList){
			//for(Opportunity opp:opps)
			//{ 
            List<String> l1=new List<String>();
           // Opportunity opp=[Select ID,LCMT_Status__c,Opportunity_Number__c from Opportunity where Opportunity_Number__c =: dw.order_number];
           if(mapOpportunity.containsKey(dw.order_number)){
                opportunity opp=mapOpportunity.get(dw.order_number);
                if(opp.LCMT_Status__c=='Unsuccessful'||opp.LCMT_Status__c==null||opp.LCMT_Status__c==''){
                    dw.LCMT_Status='FAILED';
                }
               
                else{
           if(dw.Status.id=='ORDR_BOOKD')
               dw.LCMT_Status='APPROVED';
            else if(dw.Status.id=='ORDR_OPEN')
                dw.LCMT_Status='PENDING APPPROVAL';
            else if(dw.Status.id=='ORDR_CMPLT')
                dw.LCMT_Status='APPROVED';
            else if(dw.Status.id=='ORDER_DECL')
                dw.LCMT_Status='DECLINE';
            }
            l1.add(dw.customer_name);//0
            l1.add(String.valueOf(dw.customer_id));//1
            l1.add(dw.order_number);//2
            dw.os=dw.Status.name;
            l1.add(dw.os);//3
            l1.add(String.valueOf(dw.order_value));//4
            l1.add(dw.created_date);//5
            l1.add(dw.LCMT_Status);//6
            l1.add(dw.account_manager); //7
            l1.add(dw.order_by);  //8
            l1.add(dw.country);//9
            l1.add(dw.booking_date);//10
            l1.add(dw.invoiced_date);//11
            dw.p_id=String.valueOf(dw.Order_line_items[0].product_id);
            l1.add(dw.p_id);//12
            dw.ps=dw.Order_line_items[0].Status.name;
            l1.add(dw.ps);//13
            dw.iq=String.valueOf(dw.Order_line_items[0].item_quantity);
            l1.add(dw.iq);//14
            dw.ep=String.valueOf(dw.Order_line_items[0].extended_price);
            l1.add(dw.ep);//15
            dw.dp=String.valueOf(dw.Order_line_items[0].discount_amount);
            l1.add(dw.dp);//16
            dw.se=dw.Order_line_items[0].start_date;
            l1.add(dw.se);//17
            dw.ee=dw.Order_line_items[0].end_date;
            l1.add(dw.ee);//18
            dw.pt=dw.Order_line_items[0].product_type;
            l1.add(dw.pt);//19
            dw.pn=dw.Order_line_items[0].part_number;
            l1.add(dw.pn);//20
            l1.add(dw.LCMT_Status);//21
            l1.add(dw.id);//22
            l1.add(opp.Id);//23
            dw.source=dw.order_source.id;
            l1.add(dw.source);//24
            dw.oppsize='1';
            l1.add(dw.oppsize);//25
               
            //system.debug('Order Id@@@'+dw.id);
            System.debug('Status name#####'+dw.Status.id);
             
        }
            else{
                if(dw.Status.id=='ORDR_BOOKD')
               dw.LCMT_Status='APPROVED';
            else if(dw.Status.id=='ORDR_OPEN')
                dw.LCMT_Status='PENDING APPPROVAL';
            else if(dw.Status.id=='ORDR_CMPLT')
                dw.LCMT_Status='APPROVED';
            else if(dw.Status.id=='ORDER_DECL')
                dw.LCMT_Status='DECLINE';
            
            l1.add(dw.customer_name);//0
            l1.add(String.valueOf(dw.customer_id));//1
            l1.add(dw.order_number);//2
            dw.os=dw.Status.name;
            l1.add(dw.os);//3
            l1.add(String.valueOf(dw.order_value));//4
            l1.add(dw.created_date);//5
            l1.add(dw.LCMT_Status);//6
            l1.add(dw.account_manager); //7
            l1.add(dw.order_by);  //8
            l1.add(dw.country);//9
            l1.add(dw.booking_date);//10
            l1.add(dw.invoiced_date);//11
            dw.p_id=String.valueOf(dw.Order_line_items[0].product_id);
            l1.add(dw.p_id);//12
            dw.ps=dw.Order_line_items[0].Status.name;
            l1.add(dw.ps);//13
            dw.iq=String.valueOf(dw.Order_line_items[0].item_quantity);
            l1.add(dw.iq);//14
            dw.ep=String.valueOf(dw.Order_line_items[0].extended_price);
            l1.add(dw.ep);//15
            dw.dp=String.valueOf(dw.Order_line_items[0].discount_amount);
            l1.add(dw.dp);//16
            dw.se=dw.Order_line_items[0].start_date;
            l1.add(dw.se);//17
            dw.ee=dw.Order_line_items[0].end_date;
            l1.add(dw.ee);//18
            dw.pt=dw.Order_line_items[0].product_type;
            l1.add(dw.pt);//19
            dw.pn=dw.Order_line_items[0].part_number;
            l1.add(dw.pn);//20
            l1.add(dw.LCMT_Status);//21
            l1.add(dw.id);//22
            l1.add('');//23
            dw.source=dw.order_source.id;
            dw.oppsize='0';
            l1.add(dw.source);//24
                
            l1.add(dw.oppsize);//25
            }
            m1.put(dw.order_number,l1); 
        
   // }
		}
       // }
        System.debug(m1);
        return m1;
    }
    @AuraEnabled
    public static String getPartyId(String accountId){
        System.debug(accountId);
        Account acc = [Select Id,bdmd_CR_Party_ID__c From Account where Id =: accountId LIMIT 1 ];
        return acc.bdmd_CR_Party_ID__c;
    }
    @AuraEnabled
    public static String getOrderNumber(String OppId){
        System.debug(oppId);
        Opportunity opp = [Select Id,Opportunity_Number__c From Opportunity where Id =: oppId LIMIT 1 ];
        return opp.Opportunity_Number__c;
    }
    //end of order search
  }