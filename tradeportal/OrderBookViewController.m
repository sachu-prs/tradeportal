//
//  OrderBookViewController.m
//  tradeportal
//
//  Created by Nagarajan Sathish on 23/10/14.
//
//

#import "OrderBookViewController.h"
#import "OrderBookTableViewCell.h"
#import "OrderBookDetailsViewController.h"
#import "LoginViewController.h"

@interface OrderBookViewController(){
    BOOL resultFound;
}

@property (strong, nonatomic) NSMutableData *buffer;
@property (strong, nonatomic) NSXMLParser *parser;
@property (strong, nonatomic) NSString *parseURL;
@property (strong, nonatomic) NSURLConnection *conn;
@property(strong,nonatomic)NSDictionary *statusDict;

@end

@implementation OrderBookViewController


@synthesize orders = _orders,buffer,parseURL,parser,conn,spinner,orderList=_orderList,statusDict, searchBar,orderBy,searchBtn;
OrderBookModel *obm;
DataModel *dm;

-(void)viewDidLoad{
    searchBar.delegate=self;
    statusDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                  @"CXL",@"Cancelled",
                  @"CHG",@"Changed",
                  @"FILL",@"Filled",
                  @"PARK",@"Parked",
                  @"PART",@"Partially Filled",
                  @"PCHG",@"Pending Changed",
                  @"PCXL",@"Pending Cancel",
                  @"PQ",@"Pending Queue",
                  @"Q",@"Queue",
                  @"RJCT",@"Rejected",
                  @"CXL",@"Unsolicited Cancel",
                  @"CHG",@"Part Changed",
                  @"CXL",@"Part Cancelled",
                  nil];
    
    [self.tableView registerClass: [OrderBookTableViewCell class] forCellReuseIdentifier:@"Cell"];
    orders = [[NSMutableArray alloc]init];
    orderList= [[NSMutableArray alloc]init];
    
    
    spinner.center= CGPointMake( [UIScreen mainScreen].bounds.size.width/2,[UIScreen mainScreen].bounds.size.height/2);
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    [mainWindow addSubview:spinner];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]init];
    refreshControl.tintColor = iRELOAD;
    [refreshControl addTarget:self action:@selector(reloadTableData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self searchBar].hidden = TRUE;
    [self orderBy].hidden = TRUE;
     [self reloadTableData];
    
}

-(void)reloadTableData{
    [orderList removeAllObjects];
    [orders removeAllObjects];
    [self loadOrders];
}

- (IBAction)stockSearch:(id)sender {
    [self.segmentedControl setSelectedSegmentIndex:0];
    [orders removeAllObjects];
    [orders addObjectsFromArray:orderList];
    [self.tableView reloadData];
    [self segmentedControl].hidden = TRUE;
    [self searchBtn].hidden = TRUE;
    //[self orderBy].hidden = FALSE;
    [self searchBar].hidden = FALSE;
    [searchBar becomeFirstResponder];
}


- (IBAction)hideSearch:(id)sender {
    [self segmentedControl].hidden = FALSE;
    [self searchBtn].hidden = FALSE;
    [self orderBy].hidden = TRUE;
    [self searchBar].hidden = TRUE;
    [self searchBar].text = @"";
    [orders removeAllObjects];
    [orders addObjectsFromArray:orderList];
    [self.tableView reloadData];
    [self.navigationController.navigationBar endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == searchBar){
        [self hideSearch:self];
        
    }
    return YES;
}


-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController.navigationBar endEditing:YES];
//    [self reloadTableData];
}

-(void) viewDidAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([[[[[[self tabBarController]tabBar]items]objectAtIndex:1]badgeValue] isEqualToString:@"1"]) {
        [self reloadTableData];
        [[[[[self tabBarController]tabBar]items]objectAtIndex:1]setBadgeValue:NULL];
    }
    
}


#pragma mark - Search

-(IBAction)searchOrderList:(id)sender
{
    if ([searchBar.text isEqualToString:@""]) {
        [orders removeAllObjects];
        [orders addObjectsFromArray:orderList];
        
    } else {
        NSString *searchText = searchBar.text;
        [orders removeAllObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(stockCode contains[cd] %@) or (desc contains[cd] %@) or (clientAccount contains[cd] %@)", searchText,searchText,searchText];
        [orders addObjectsFromArray:[orderList filteredArrayUsingPredicate:predicate]];

    }
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [orders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    OrderBookTableViewCell *cell = (OrderBookTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"OrderBookTableViewCell"];
    
    if(cell == nil){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OrderBookTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if([orders count]>0){
        NSMutableString *stock = [[[orders objectAtIndex:[indexPath row]]stockCode]mutableCopy];
        UIColor *textColor = [[UIColor alloc]init];
//        [[cell stockCode] setText:[[orders objectAtIndex:[indexPath row]]stockCode]];
        [[cell side] setText:[[orders objectAtIndex:[indexPath row]]clientAccount]];
        if([[[orders objectAtIndex:[indexPath row]]side] isEqualToString:@"Buy"]){
            [stock appendString:@" (B)"];
             textColor = iGREEN;
        }
        if([[[orders objectAtIndex:[indexPath row]]side] isEqualToString:@"Sell"]){
            [stock appendString:@" (S)"];
            textColor = iRED;
        }
        NSMutableAttributedString * string = [[NSMutableAttributedString alloc]initWithString:stock];
//        NSLog(@"%lu\t%lu",(unsigned long)stock.length,(unsigned long)string.length);
        [string addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(stock.length-2, 1)];
        
        [[cell stockCode] setAttributedText:string];
        [[cell price] setText:[[orders objectAtIndex:[indexPath row]]orderPrice]];
        [[cell quantity] setText:[[orders objectAtIndex:[indexPath row]]orderQty]];
        [[cell qtyFilled] setText:[[orders objectAtIndex:[indexPath row]]qtyFilled]];
        [[cell status] setText:[statusDict valueForKey:[[orders objectAtIndex:[indexPath row]]status]]];
    }
    return cell;
}


-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UITableViewCell *header = [tableView dequeueReusableCellWithIdentifier:@"tableHeader"];
    return header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 38.0;
}


#pragma mark - Service

-(void)loadOrders{
    
    self.parseURL = @"getOrders";
    NSString *soapRequest = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                             "<soap:Body>"
                             "<GetOrderByUserID xmlns=\"http://OMS/\">"
                             "<UserSession>%@</UserSession>"
                             "<UserID>%@</UserID>"
                             "</GetOrderByUserID>"
                             "</soap:Body>"
                             "</soap:Envelope>", dm.sessionID,dm.userID];
    //NSLog(@"SoapRequest is %@" , soapRequest);
    NSURL *url =[NSURL URLWithString:@"http://192.168.174.109/oms/ws_rsoms.asmx?op=GetOrderByUserID"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req addValue:@"http://OMS/GetOrderByUserID" forHTTPHeaderField:@"SOAPAction"];
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapRequest length]];
    [req addValue:msgLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[soapRequest dataUsingEncoding:NSUTF8StringEncoding]];
    [orders removeAllObjects];
    [orderList removeAllObjects];
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    spinner.hidesWhenStopped=YES;
    [spinner startAnimating];
    if (conn) {
        buffer = [NSMutableData data];
    }
    
}


-(void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *) response {
    [buffer setLength:0];
}
-(void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data {
    [buffer appendData:data];
}
-(void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error {
    
}

-(void) connectionDidFinishLoading:(NSURLConnection *) connection {
    
    //NSLog(@"\n\nDone with bytes %lu", (unsigned long)[buffer length]);
    NSMutableString *theXML =
    [[NSMutableString alloc] initWithBytes:[buffer mutableBytes]
                                    length:[buffer length]
                                  encoding:NSUTF8StringEncoding];
    [theXML replaceOccurrencesOfString:@"&lt;"
                            withString:@"<" options:0
                                 range:NSMakeRange(0, [theXML length])];
    [theXML replaceOccurrencesOfString:@"&gt;"
                            withString:@">" options:0
                                 range:NSMakeRange(0, [theXML length])];
    NSLog(@"\n\nSoap Response is %@",theXML);
    [orderList removeAllObjects];
    [orders removeAllObjects];
    [buffer setData:[theXML dataUsingEncoding:NSUTF8StringEncoding]];
    parser =[[NSXMLParser alloc]initWithData:buffer];
    [parser setDelegate:self];
    [parser parse];
    
}

-(void) parser:(NSXMLParser *) parser didStartElement:(NSString *) elementName
  namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qName attributes:(NSDictionary *) attributeDict {
    
    //parse the data
    if ([parseURL isEqualToString:@"getOrders"]) {
        
        if([elementName isEqualToString:@"GetOrderByUserIDResult"]){
            ////NSLog(@"%@",[attributeDict description]);
            resultFound=NO;
        }

        if ([elementName isEqualToString:@"z:row"]) {
            resultFound=YES;
            OrderBookModel *order = [[OrderBookModel alloc]init];
            order.refNo = [attributeDict objectForKey:@"c8"];
            order.clientAccount = [attributeDict objectForKey:@"c9"];
            order.stockCode = [attributeDict objectForKey:@"Stock"];
            order.desc = [attributeDict objectForKey:@"c43"];
            order.exchange = [attributeDict objectForKey:@"Exchange"];
            order.side = [attributeDict objectForKey:@"c4"];
            order.orderType = [attributeDict objectForKey:@"c24"];
            order.status = [attributeDict objectForKey:@"c7"];
            order.orderQty = [attributeDict objectForKey:@"OrderQty"];
            order.qtyFilled = [attributeDict objectForKey:@"FilledQty"];
            order.orderPrice = [attributeDict objectForKey:@"OrderPrice"];
            order.avgPrice = [attributeDict objectForKey:@"AvePrice"];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
            order.orderDate = [dateFormatter dateFromString:[attributeDict objectForKey:@"c11"]];
            order.currency = [attributeDict objectForKey:@"c22"];
            //Add arrribute value to array
            [orderList addObject:order];
            [orders addObject:order];
            [self.tableView reloadData];
            
        }
    }
    [spinner stopAnimating];
    [self.refreshControl endRefreshing];
}


- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) string {
    NSString *msg;
    BOOL flag=FALSE;
    if(!resultFound){
        if([[string substringToIndex:1] isEqualToString:@"R"]){
            msg = @"Some Technical Error...\nPlease Try again...";
            flag=TRUE;
        }
        else if([[string substringToIndex:1] isEqualToString:@"E"]){
            //NSLog(@"E error");
            msg = @"User has logged on elsewhere!";
            [self dismissViewControllerAnimated:YES completion:nil];
            [[self navigationController]popToRootViewControllerAnimated:YES];
            flag=TRUE;
        }
        if (flag) {
            
            UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [toast show];
            int duration = 1.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [toast dismissWithClickedButtonIndex:0 animated:YES];
            });
            
        }
        resultFound=YES;
    }
}

-(IBAction)indexChanged:(UISegmentedControl *)sender
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
            [orders removeAllObjects];
            [orders addObjectsFromArray:orderList];
            [self.tableView reloadData];
            break;
            
        case 1:
            [orders removeAllObjects];
            for(OrderBookModel *ob in orderList){
                if([ob.status isEqualToString:@"Filled"]){
                    [orders addObject:ob];
                }
            }
            [self.tableView reloadData];
            break;
        case 2:
            [orders removeAllObjects];
            for(OrderBookModel *ob in orderList){
                if([ob.status isEqualToString:@"Queue"]){
                    [orders addObject:ob];
                }
            }
            [self.tableView reloadData];
            break;
        default:
            break;
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"orderDetail"]) {
        
        OrderBookDetailsViewController *vc = (OrderBookDetailsViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        OrderBookModel *obm = [orders objectAtIndex:indexPath.row];
        vc.order = obm;
        vc.orderBook = self;
    }
    
}


@end
