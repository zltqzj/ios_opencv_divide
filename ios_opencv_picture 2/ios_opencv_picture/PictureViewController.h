//
//  PictureViewController.h
//  ios_opencv_picture
//
//  Created by Sinosoft on 8/6/13.
//  Copyright (c) 2013 com.Sinosoft. All rights reserved.
//

#import <UIKit/UIKit.h>
 
@interface PictureViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
 
@property(strong,nonatomic) IBOutlet UIImageView* src1;//样本图片

@property(strong,nonatomic) IBOutlet UIImageView* dst1;//样本分割区域二值化

@property(strong,nonatomic) IBOutlet UIImageView* src2;  //比较图片

@property(strong,nonatomic) IBOutlet UIImageView* dst2;// 比较图片二值化



 

@end
