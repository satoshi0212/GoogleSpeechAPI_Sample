//
//  ViewController.m
//  GoogleSearchApiSample
//
//  Created by satoshi hattori on 2016/01/11.
//  Copyright © 2016年 satoshi hattori. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "ViewController.h"

// TODO:change value
#define GOOGLE_SPEECH_API_KEY @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

@interface ViewController () <NSURLConnectionDataDelegate, AVAudioRecorderDelegate>

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) UIButton *recBtn;
@property (nonatomic, strong) UILabel *txtlbl;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.recBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    {
        self.recBtn.frame = CGRectMake(20, 175, 120, 40);
        [self.recBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.recBtn setTitle:@"入力" forState:UIControlStateNormal];
        [self.recBtn setTitle:@"入力中..." forState:UIControlStateSelected];
        self.recBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        self.recBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.recBtn.layer.borderWidth = 1.0;
        self.recBtn.layer.cornerRadius = 8.0;
        [self.recBtn addTarget:self action:@selector(recBtn_action:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.recBtn];
    }
    
    self.txtlbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 220, 280, 60)];
    {
        self.txtlbl.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.txtlbl.layer.borderWidth = 1.0;
        
        [self.view addSubview:self.txtlbl];
    }
}

#pragma mark - Action

- (void)recBtn_action:(UIButton *)sender
{
    if (sender.selected) {
        [self stopRecord];
    }
    else {
        [self startRecord];
    }
    
    sender.selected = !sender.selected;
}

#pragma mark - NSURLDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSError *jsonError = nil;
    id jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
    
    if ([jsonData[@"result"] count] > 0) {
        
        NSArray *resultList = jsonData[@"result"];
        NSDictionary *dic = resultList[0];
        NSArray *alternativeList = dic[@"alternative"];
        
        NSLog(@"google result:%@", alternativeList[0][@"transcript"]);
        
        NSString *str = [NSString stringWithFormat:@"%@", alternativeList[0][@"transcript"]];
        
        self.txtlbl.text = str;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
}

#pragma mark - Google Speech API

- (void)callGoogleRecognizeApi:(NSData *)data
{
    NSString *urlStr = [NSString stringWithFormat:@"https://www.google.com/speech-api/v2/recognize?lang=ja-jp&key=%@", GOOGLE_SPEECH_API_KEY];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request addValue:@"audio/l16; rate=16000" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"chromium" forHTTPHeaderField:@"client"];
    
    [request setHTTPBody:data];
    
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)startRecord
{
    self.filePath = [self makeFilePath];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    
    NSDictionary *settings = @{AVFormatIDKey:[NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM],
                               AVSampleRateKey:[NSNumber numberWithFloat:16000.0],
                               AVNumberOfChannelsKey:[NSNumber numberWithUnsignedInt:1],
                               AVLinearPCMBitDepthKey:[NSNumber numberWithUnsignedInt:16]};
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:self.filePath] settings:settings error:nil];
    self.recorder.delegate = self;
    
    [self.recorder prepareToRecord];
    [self.recorder recordForDuration:15.0];
}

- (void)stopRecord
{
    [self.recorder stop];
}

- (NSString *)makeFilePath
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *fileName = [NSString stringWithFormat:@"%@.wav", [formatter stringFromDate:[NSDate date]]];
    
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (!flag) {
        return;
    }

    NSData *data = [NSData dataWithContentsOfFile:self.filePath];

    // 必要に応じ一時ファイル削除
    
    [self callGoogleRecognizeApi:data];
}

@end
