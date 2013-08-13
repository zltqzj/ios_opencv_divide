//
//  PictureViewController.m
//  ios_opencv_picture
//
//  Created by Sinosoft on 8/6/13.
//  Copyright (c) 2013 com.Sinosoft. All rights reserved.
//

#import "PictureViewController.h"
 
@interface PictureViewController ()

@end

@implementation PictureViewController

@synthesize imageView = _imageView;
@synthesize imageView_2 = _imageView_2;
 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"the Comparison of picture";
    }
    return self;
}

#pragma mark - IBAction

-(IBAction)chooseFromPhotos:(id)sender  // 选照片按钮
{
    UIImagePickerController *pc = [[UIImagePickerController alloc]init];
    pc.delegate = self;
    pc.allowsEditing = NO;
    pc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:pc animated:YES completion:nil];
}

-(IBAction)takePhoto:(id)sender   // 拍照按钮
{
    
    UIImagePickerController * imagePickerController = [[UIImagePickerController alloc]init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;// 相机
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = NO;
    // 图层～～
    UIImageView* imagev = [[UIImageView alloc]  initWithFrame:CGRectMake(0, 0,   [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-96)];
    imagev.image = self.imageView.image;
    imagev.alpha = 0.5;
    imagePickerController.cameraOverlayView = imagev;
    [self presentViewController:imagePickerController animated:YES completion:nil];
     
    
}

#pragma mark - UIImagePickerControllerDelegate

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // 拍照
        self.imageView_2.image = image;
        [self dismissViewControllerAnimated:YES completion:nil];
        [self pictureCompare];// 调用图片对比方法
    }
    else{
        // 选照片
        self.imageView.image = image;
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}


 
#pragma mark - opencv method 
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

+ (UIImage *)scaleAndRotateImageBackCamera:(UIImage *)image
{
    static int kMaxResolution = 640;
    CGImageRef imgRef = image.CGImage;
    CGFloat width = CGImageGetWidth( imgRef );
    CGFloat height = CGImageGetHeight( imgRef );
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake( 0, 0, width, height );
    if ( width > kMaxResolution || height > kMaxResolution ) {
        CGFloat ratio = width/height;
        if ( ratio > 1 ) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake( CGImageGetWidth(imgRef), CGImageGetHeight(imgRef) );
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch( orient ) {
        case UIImageOrientationUp:
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown:
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRight:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }
    UIGraphicsBeginImageContext( bounds.size );
    CGContextRef context = UIGraphicsGetCurrentContext();
    if ( orient == UIImageOrientationRight || orient == UIImageOrientationLeft ) {
        CGContextScaleCTM( context, -scaleRatio, scaleRatio );
        CGContextTranslateCTM( context, -height, 0 );
    }
    else {
        CGContextScaleCTM( context, scaleRatio, -scaleRatio );
        CGContextTranslateCTM( context, 0, -height );
    }
    CGContextConcatCTM( context, transform );
    CGContextDrawImage( UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef );
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return returnImage;
}

+ (UIImage *)scaleAndRotateImageFrontCamera:(UIImage *)image
{
    static int kMaxResolution = 640;
    CGImageRef imgRef = image.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake( 0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        } else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
        case UIImageOrientationUp:
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown:
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }
    UIGraphicsBeginImageContext( bounds.size );
    CGContextRef context = UIGraphicsGetCurrentContext();
    if ( orient == UIImageOrientationRight || orient == UIImageOrientationLeft ) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    CGContextConcatCTM( context, transform );
    CGContextDrawImage( UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef );
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return returnImage;
}

- (void)getRectImage:(UIImage*)img{
    
    CGSize size = [img size];
    
    int width = size.width;
    
    int height = size.height;
    
    // the pixels will be painted to this array
    
    uint32_t *mypixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    
    memset(mypixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    
    CGContextRef context = CGBitmapContextCreate(mypixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [img CGImage]);
    
    int tt = 1;
    
    CGFloat intensity;
    
    
    bool bFind = NO;
    int  nOrignX = 0;
    int nOrignY = 0;
    int nWidth = width;
    int nHeight = height;
    for(int y = 0; y < height; y++) {
        
        for(int x = 0; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &mypixels[y * width + x];
            intensity = (rgbaPixel[tt] + rgbaPixel[tt + 1] + rgbaPixel[tt + 2]) / 3. / 255.;
            if ((int)intensity == 1) {
                
                bFind = YES;
                nOrignX = x;
                nOrignY = y;
                break;
            }
        }
        if (bFind ) {
            break;
        }
    }
    //NSLog(@"---fOrignX:%d .....fOrignY:%d...width:%d..height:%d..",nOrignX,nOrignY,width,height);
    for(int x = width; x > nOrignX; x--) {
        uint8_t *rgbaPixel = (uint8_t *) &mypixels[(nOrignY + 5) * width + x];
        intensity = (rgbaPixel[tt] + rgbaPixel[tt + 1] + rgbaPixel[tt + 2]) / 3. / 255.;
        if ((int)intensity == 1) {
            nWidth = x - nOrignX;
            break;
        }
    }
    
    for(int y = height; y >nOrignY; y--) {
        uint8_t *rgbaPixel = (uint8_t *) &mypixels[y * width + nOrignX];
        intensity = (rgbaPixel[tt] + rgbaPixel[tt + 1] + rgbaPixel[tt + 2]) / 3. / 255.;
        if ((int)intensity == 1) {
            nHeight = y - nOrignY;
            break;
        }
    }
    free(mypixels);
    
    _nOrignX = nOrignX;
    _nOrignY = nOrignY;
    _nWidth = nWidth;
    _nHeight = nHeight;
    
    NSLog(@"----x:%d.y:%d.width:%d.height:%d",_nOrignX,_nOrignY,_nWidth,_nHeight);
}

// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
                                       cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4
                                       );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

// NOTE You should convert color mode as RGB before passing to this function
- (UIImage *)UIImageFromIplImage:(IplImage *)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Allocating the buffer for CGImage
    NSData *data =
    [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // Creating CGImage from chunk of IplImage
    CGImageRef imageRef = CGImageCreate(
                                        image->width, image->height,
                                        image->depth, image->depth * image->nChannels, image->widthStep,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    // Getting UIImage from CGImage
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}


#pragma mark - custom method

// OSTU算法求出阈值
int  Otsu(unsigned char* pGrayImg , int iWidth , int iHeight)
{
    if((pGrayImg==0)||(iWidth<=0)||(iHeight<=0))return -1;
    int ihist[256];
    int thresholdValue=0; // „–÷µ
    int n, n1, n2 ;
    double m1, m2, sum, csum, fmax, sb;
    int i,j,k;
    memset(ihist, 0, sizeof(ihist));
    n=iHeight*iWidth;
    sum = csum = 0.0;
    fmax = -1.0;
    n1 = 0;
    for(i=0; i < iHeight; i++)
    {
        for(j=0; j < iWidth; j++)
        {
            ihist[*pGrayImg]++;
            pGrayImg++;
        }
    }
    pGrayImg -= n;
    for (k=0; k <= 255; k++)
    {
        sum += (double) k * (double) ihist[k];
    }
    for (k=0; k <=255; k++)
    {
        n1 += ihist[k];
        if(n1==0)continue;
        n2 = n - n1;
        if(n2==0)break;
        csum += (double)k *ihist[k];
        m1 = csum/n1;
        m2 = (sum-csum)/n2;
        sb = (double) n1 *(double) n2 *(m1 - m2) * (m1 - m2);
        if (sb > fmax)
        {
            fmax = sb;
            thresholdValue = k;
        }
    }
    return(thresholdValue);
}


// picture compare
-(void)pictureCompare
{
    // 第一张图片灰度图
    cv::Mat mat = [self cvMatFromUIImage:_imageView.image];
    cv::Mat greyMat;
    cv::cvtColor(mat , greyMat, CV_BGR2GRAY);
    cv::Mat binaryMat;
    
    IplImage i1 = greyMat;
    unsigned char* data1 = (unsigned char*)i1.imageData;
    int threshold =  Otsu(data1, i1.width, i1.height);
    printf("阈值：%d\n",threshold);
    
    
    // 第二张图片灰度图
    cv::Mat mat2=[self cvMatFromUIImage:_imageView_2.image];
    cv::Mat greyMat2;
    cv::cvtColor(mat2, greyMat2, CV_BGR2GRAY);
    cv::Mat binaryMat2;
    
    // 两张图片二值化
    cv::threshold(greyMat, binaryMat, threshold, 255, cv::THRESH_BINARY);
    cv::threshold(greyMat2, binaryMat2, threshold, 255, cv::THRESH_BINARY);
    
    
    // cvmat->iplimage
    IplImage binary1 = binaryMat;
    IplImage binary2 = binaryMat2;
    
    unsigned char* binaryData1 = (unsigned char*)binary1.imageData;
    unsigned char* binaryData2 = (unsigned char*)binary2.imageData;
    
    int s = binary1.imageSize;  // 整个图片大小
    printf("图片的大小：%d\n",s);
    int count = 0;// 笔的像素点
    
    for (int i=200000; i<250000; i++)
    {
        *(binaryData1+i) = 128;
    }
    
    
    printf("不同区域像素点的个数：%d\n",count);
    
    // 第一张图片cvmat->uiimage
    UIImage *image = [[UIImage alloc] init];
    image = [self UIImageFromCVMat:binaryMat];
    self.imageView.image = image;
    
    // 第二张图片cvmat->uiimage
    UIImage* image2 = [[UIImage alloc] init];
    image2  = [self UIImageFromCVMat:binaryMat2];
    self.imageView_2.image = image2;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    
    IplImage *ip1 = [self CreateIplImageFromUIImage:_imageView.image];
    int width  = ip1->width;
    int height = ip1->height;
    printf("图片大小%d,%d\n",width,height);
    
    cvSetImageROI(ip1, cvRect(400, 1000,1200,800));
    IplImage* dst = cvCreateImage(cvSize(1200 ,800), ip1->depth, ip1->nChannels);
    cvCopy(ip1, dst,0);
    cvResetImageROI(ip1);
    
    self.imageView_2.image = [self UIImageFromIplImage:dst];
    
    cv::Mat matImage2 = [self cvMatFromUIImage:_imageView_2.image];
    cv::Mat greyImage2 ;
    cv::cvtColor(matImage2, greyImage2, CV_BGR2GRAY);
    cv::Mat bianryImage2;
    IplImage image2  = greyImage2;
    unsigned char* dataImage2 = (unsigned char*)image2.imageData;
    int threshold = Otsu(dataImage2,image2.width,image2.height);
    printf("阈值：%d\n",threshold);
    cv::threshold(greyImage2, bianryImage2, threshold, 255, cv::THRESH_BINARY);
    UIImage* image = [[UIImage alloc ]init];
    image = [self UIImageFromCVMat:bianryImage2];
    self.imageView_2.image = image;
    
    //setting compare picture binary and divide
    
    IplImage* ip2 = [self CreateIplImageFromUIImage:_comImageView.image];
    int width2 = ip2->width;
    int height2 = ip2->height;
    printf("图片大小%d,%d\n",width2,height2);
    cvSetImageROI(ip2, cvRect(400, 1000, 1200, 800));
    IplImage* dst2 = cvCreateImage(cvSize(1200,800), ip2->depth, ip2->nChannels);
    cvCopy(ip2, dst2,0);
    cvResetImageROI(ip2);
    self.comImageView2.image = [self UIImageFromIplImage:dst2];
    cv::Mat matcomImage = [self cvMatFromUIImage:_comImageView2.image];
    cv::Mat greycomImage2 ;
    cv::cvtColor(matcomImage, greycomImage2, CV_BGR2GRAY);
    cv::Mat binarycomImage;
   
  
    cv::threshold(greycomImage2, binarycomImage, threshold, 255, cv::THRESH_BINARY);
    UIImage* comimage2 = [[UIImage alloc] init];
    comimage2 = [self UIImageFromCVMat:binarycomImage];
    self.comImageView2.image = comimage2;
    
    
    
    
        
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
