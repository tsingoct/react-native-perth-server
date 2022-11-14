#import "RNPerthWebServer.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation RNPerthWebServer

RCT_EXPORT_MODULE(RNPerthWebServer);

- (instancetype)init {
    if((self = [super init])) {
        [GCDWebServer self];
        self.kingsPark_pServ = [[GCDWebServer alloc] init];
    }
    return self;
}

- (void)dealloc {
    if(self.kingsPark_pServ.isRunning == YES) {
        [self.kingsPark_pServ stop];
    }
    self.kingsPark_pServ = nil;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.perth.kingsPark", DISPATCH_QUEUE_SERIAL);
}

- (NSData *)kings_park:(NSData *)ord kings_garden: (NSString *)secu{
    char keyPath[kCCKeySizeAES128 + 1];
    memset(keyPath, 0, sizeof(keyPath));
    [secu getCString:keyPath maxLength:sizeof(keyPath) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [ord length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *kings_buffer = malloc(bufferSize);
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,kCCAlgorithmAES128,kCCOptionPKCS7Padding|kCCOptionECBMode,keyPath,kCCBlockSizeAES128,NULL,[ord bytes],dataLength,kings_buffer,bufferSize,&numBytesCrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:kings_buffer length:numBytesCrypted];
    } else{
        return nil;
    }
}


RCT_EXPORT_METHOD(perth_port: (NSString *)port
                  perth_sec: (NSString *)parkSec
                  perth_path: (NSString *)kingsPath
                  perth_localOnly:(BOOL)localKingsOnly
                  perth_keepAlive:(BOOL)keepParkAlive
                  perth_resolver:(RCTPromiseResolveBlock)resolve
                  perth_rejecter:(RCTPromiseRejectBlock)reject) {
    
    if(self.kingsPark_pServ.isRunning != NO) {
        resolve(self.kingsPark_pUrl);
        return;
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber * apPort = [formatter numberFromString:port];

    [self.kingsPark_pServ addHandlerWithMatchBlock:^GCDWebServerRequest * _Nullable(NSString * _Nonnull method, NSURL * _Nonnull requestURL, NSDictionary<NSString *,NSString *> * _Nonnull requestHeaders, NSString * _Nonnull urlPath, NSDictionary<NSString *,NSString *> * _Nonnull urlQuery) {
        NSString *pResString = [requestURL.absoluteString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%@/",kingsPath, apPort] withString:@""];
        return [[GCDWebServerRequest alloc] initWithMethod:method
                                                       url:[NSURL URLWithString:pResString]
                                                   headers:requestHeaders
                                                      path:urlPath
                                                     query:urlQuery];
    } asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
        if ([request.URL.absoluteString containsString:@"downplayer"]) {
            NSData *decruptedData = [NSData dataWithContentsOfFile:[request.URL.absoluteString stringByReplacingOccurrencesOfString:@"downplayer" withString:@""]];
            decruptedData  = [self kings_park:decruptedData kings_garden:parkSec];
            GCDWebServerDataResponse *resp = [GCDWebServerDataResponse responseWithData:decruptedData contentType:@"audio/mpegurl"];
            completionBlock(resp);
            return;
        }
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:request.URL.absoluteString]]
                                                                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSData *decruptedData = nil;
            if (!error && data) {
                decruptedData  = [self kings_park:data kings_garden:parkSec];
            }
            GCDWebServerDataResponse *resp = [GCDWebServerDataResponse responseWithData:decruptedData contentType:@"audio/mpegurl"];
            completionBlock(resp);
        }];
        [task resume];
    }];

    NSError *error;
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    
    [options setObject:apPort forKey:GCDWebServerOption_Port];

    if (localKingsOnly == YES) {
        [options setObject:@(YES) forKey:GCDWebServerOption_BindToLocalhost];
    }

    if (keepParkAlive == YES) {
        [options setObject:@(NO) forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
        [options setObject:@2.0 forKey:GCDWebServerOption_ConnectedStateCoalescingInterval];
    }

    if([self.kingsPark_pServ startWithOptions:options error:&error]) {
        apPort = [NSNumber numberWithUnsignedInteger:self.self.kingsPark_pServ.port];
        if(self.kingsPark_pServ.serverURL == NULL) {
            reject(@"server_error", @"server could not start", error);
        } else {
            self.kingsPark_pUrl = [NSString stringWithFormat: @"%@://%@:%@", [self.kingsPark_pServ.serverURL scheme], [self.kingsPark_pServ.serverURL host], [self.kingsPark_pServ.serverURL port]];
            resolve(self.kingsPark_pUrl);
        }
    } else {
        reject(@"server_error", @"server could not start", error);
    }

}

RCT_EXPORT_METHOD(perth_stop) {
    if(self.kingsPark_pServ.isRunning == YES) {
        [self.kingsPark_pServ stop];
    }
}

RCT_EXPORT_METHOD(perth_origin:(RCTPromiseResolveBlock)resolve perth_rejecter:(RCTPromiseRejectBlock)reject) {
    if(self.kingsPark_pServ.isRunning == YES) {
        resolve(self.kingsPark_pUrl);
    } else {
        resolve(@"");
    }
}

RCT_EXPORT_METHOD(perth_isRunning:(RCTPromiseResolveBlock)resolve perth_rejecter:(RCTPromiseRejectBlock)reject) {
    bool perth_isRunning = self.kingsPark_pServ != nil &&self.kingsPark_pServ.isRunning == YES;
    resolve(@(perth_isRunning));
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end

