#line 1 "/Users/john/Documents/RottenRatings/RottenRatings/RottenRatings.xm"
#define kBundlePath @"/Library/MobileSubstrate/DynamicLibraries/RottenRatings.bundle"
#include <Videos/VideosArtworkCell.h>
#include <UIKit/UIKit.h>

#include <logos/logos.h>
#include <substrate.h>
@class VideosArtworkCell; 
static void (*_logos_orig$_ungrouped$VideosArtworkCell$setTitle$)(VideosArtworkCell*, SEL, NSString* ); static void _logos_method$_ungrouped$VideosArtworkCell$setTitle$(VideosArtworkCell*, SEL, NSString* ); 

#line 5 "/Users/john/Documents/RottenRatings/RottenRatings/RottenRatings.xm"

static void _logos_method$_ungrouped$VideosArtworkCell$setTitle$(VideosArtworkCell* self, SEL _cmd, NSString*  title) {
    
    _logos_orig$_ungrouped$VideosArtworkCell$setTitle$(self, _cmd, title);
    
    UIImageView* ImageView = self.artworkView;
    if(ImageView==nil)
        return;
    
    UIImage* img = ImageView.image;
    UIGraphicsBeginImageContext(img.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if(context!=nil && img!=nil)
    {
        NSString *URL = @"http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=42z34f7h6erk6de8mmbsrten&page_limit=1&q=";
        NSString *query = [title stringByReplacingOccurrencesOfString: @" " withString:@"+"];
        URL = [URL stringByAppendingString:query];
        
        
        int tries = 0;
        NSData* data = nil;
        while(data==nil && tries < 20)
        {
            data = [NSData dataWithContentsOfURL:[NSURL URLWithString:URL]];
            tries++;
        }
        
        if(data != nil)
        {
            NSError *e = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error:&e];
            
            
            if(json != nil)
            {
                NSArray *movies = (NSArray *)[json objectForKey:@"movies"];
                if(movies != nil)
                    json = [movies objectAtIndex: 0];
                else
                    json = nil;
            }
            
            if(json != nil)
            {
                
                NSDictionary *ratings = (NSDictionary *)[json objectForKey:@"ratings"];
                if(ratings != nil)
                {
                    
                    NSNumber *critic = [ratings objectForKey:@"critics_score"];
                    
                    
                    UIFont *font = [UIFont fontWithName:@"Arial" size:16];
                    NSString *rating = [NSString stringWithFormat:@"%@%%",[critic stringValue]];
                    CGSize textSize = [rating sizeWithAttributes:@{NSFontAttributeName:font}];

                    [img drawInRect:CGRectMake(0.0,0.0,img.size.width, img.size.height)];
    
                    const int margin = 6;
                    NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
                    NSString *imagePath = [bundle pathForResource:@"tomato" ofType:@"png"];
                    UIImage *tomato = [UIImage imageWithContentsOfFile:imagePath];
                    
                    float y=img.size.height-tomato.size.height-margin;
                    [tomato drawAtPoint:CGPointMake(margin,y)];
                     
                    
                    float x=margin + (tomato.size.width/2 - textSize.width/2);
                    y=img.size.height - tomato.size.height/2 - textSize.height/2;
                    
                    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
                    shadow.shadowColor = [UIColor blackColor];
                    shadow.shadowBlurRadius = 2.0;
                    shadow.shadowOffset = CGSizeMake(0.0,1.0);
                    
                    [rating drawAtPoint:CGPointMake(x, y)
                         withAttributes:@{NSFontAttributeName:font,
                                          NSForegroundColorAttributeName:[UIColor whiteColor],
                                          NSShadowAttributeName:shadow}];
                }
            }
        }
        ImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    }
}

static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$VideosArtworkCell = objc_getClass("VideosArtworkCell"); MSHookMessageEx(_logos_class$_ungrouped$VideosArtworkCell, @selector(setTitle:), (IMP)&_logos_method$_ungrouped$VideosArtworkCell$setTitle$, (IMP*)&_logos_orig$_ungrouped$VideosArtworkCell$setTitle$);} }
#line 92 "/Users/john/Documents/RottenRatings/RottenRatings/RottenRatings.xm"
