#line 1 "/Users/john/Documents/RottenRatings/RottenRatings/RottenRatings.xm"
#include <Videos/VideosArtworkCell.h>
#include <Videos/VideosMovieDetailCell.h>
#include <MediaPlayer/MPMediaItem.h>
#include <UIKit/UIKit.h>

#define kBundlePath @"/Library/MobileSubstrate/DynamicLibraries/RottenRatings.bundle"
#define PreferencesFilePath [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.rebelzoo.RottenRatings.plist"]

static NSDictionary *prefsDict = nil;

static NSMutableDictionary *overlayImages=nil;
static NSMutableDictionary *rtRatingDictionary=nil;
static NSMutableDictionary *imdbRatingDictionary=nil;

static void loadPreferences() {
    if(prefsDict==nil)
    {
        prefsDict = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
    }
}

static bool getPrefBool(NSString *item, bool defaultValue){
    id value=[prefsDict objectForKey:item];
    bool boolValue;
    if(value!=nil){
        boolValue = [value boolValue];
    } else {
        boolValue = defaultValue;
    }
    return boolValue;
}

static NSData* getDataFromURL(NSString *URL)
{
    int tries = 0;
    NSData* data = nil;
    while(data==nil && tries < 1000)
    {
        data = [NSData dataWithContentsOfURL:[NSURL URLWithString:URL]];
        tries++;
        
        if(data==nil && tries>3) {
            
            int wait=(arc4random()%100)*tries;
            usleep(wait);
        }
    }
    return data;
}

struct rottenTomatoRatings
{
    float critic;
    float audience;
};

static rottenTomatoRatings getRottenTomatoesRating(NSString *title)
{
    NSString *query = [title stringByReplacingOccurrencesOfString: @" " withString:@"+"];
    NSString *URL = @"http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=42z34f7h6erk6de8mmbsrten&page_limit=1&q=";
    URL = [URL stringByAppendingString:query];
    
    rottenTomatoRatings rtRatings;
    rtRatings.critic = 0;
    rtRatings.audience = 0;
    
    NSData *data=getDataFromURL(URL);
    if(data != nil)
    {
        NSError *e = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error:&e];
        
        if(json != nil)
        {
            NSNumber *total = [json objectForKey:@"total"];
            if(![total isEqual:@0]){
                NSArray *movies = (NSArray *)[json objectForKey:@"movies"];
                if(movies != nil && [movies count] > 0)
                    json = [movies objectAtIndex: 0];
                else
                    json = nil;
            }
            else {
                json = nil;
            }
        }
        
        if(json != nil)
        {
            NSDictionary *ratings = (NSDictionary *)[json objectForKey:@"ratings"];
            if(ratings != nil)
            {
                rtRatings.critic = [[ratings objectForKey:@"critics_score"] floatValue];
                rtRatings.audience = [[ratings objectForKey:@"audience_score"] floatValue];
                
                if(rtRatingDictionary==nil)
                    rtRatingDictionary=[[NSMutableDictionary alloc] init];
                [rtRatingDictionary setValue:[NSValue value:&rtRatings withObjCType:@encode(rottenTomatoRatings)] forKey:title];
            }
        }
    }
    
    return rtRatings;
}

struct imdbRatings
{
    float Metascore;
    float imdbRating;
};

static imdbRatings getImdbRating(NSString *title)
{
    NSString *query = [title stringByReplacingOccurrencesOfString: @" " withString:@"+"];
    NSString *URL = @"http://www.omdbapi.com/?i=&t=";
    URL = [URL stringByAppendingString:query];
    
    imdbRatings ratings;
    ratings.Metascore = 0;
    ratings.imdbRating = 0;
    
    NSData *data = getDataFromURL(URL);
    if(data != nil)
    {
        NSError *e = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error:&e];
        
        if(json != nil)
        {
            ratings.Metascore = [[json objectForKey:@"Metascore"] floatValue];
            ratings.imdbRating = [[json objectForKey:@"imdbRating"] floatValue];
            
            if(imdbRatingDictionary==nil)
                imdbRatingDictionary=[[NSMutableDictionary alloc] init];
            [imdbRatingDictionary setValue:[NSValue value:&ratings withObjCType:@encode(imdbRatings)] forKey:title];
        }
    }
    
    return ratings;
}

static void beginImageContext(CGSize frameSize){
    CGFloat scale = 1.0;
    if([[UIScreen mainScreen]respondsToSelector:@selector(scale)]) {
        CGFloat tmp = [[UIScreen mainScreen]scale];
        if(tmp > 1.5) {
            scale = 2.0;
        }
    }
    if(scale > 1.5) {
        UIGraphicsBeginImageContextWithOptions(frameSize, NO, scale);
    }
    else {
        UIGraphicsBeginImageContext(frameSize);
    }
}

static UIImage* scaleImage(UIImage *image, double scale) {
    CGSize scaled = CGSizeMake(image.size.width*scale, image.size.height*scale);
    beginImageContext(scaled);
    [image drawInRect:CGRectMake(0, 0, scaled.width, scaled.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


static UIImage* generateOverlay(NSString *title, bool scaleDown)
{
    const int margin = 4;
    const int padding = 2;
    float x=margin;
    
    UIFont *font = [UIFont fontWithName:@"Arial" size:16];
    UIFont *titleFont = [UIFont fontWithName:@"Arial" size:12];
    CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName:titleFont}];
    
    NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
    NSString *rating=nil;
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowBlurRadius = 2.0;
    shadow.shadowOffset = CGSizeMake(0.0,1.0);
    
    bool enableRottenTomatoes = getPrefBool(@"enableRottenTomatoes", YES);
    bool enableRottenTomatoesAudience = getPrefBool(@"enableRottenTomatoesAudience", NO);
    bool enableIMDBrating = getPrefBool(@"enableIMDBrating", NO);
    bool enableIMDBmeta = getPrefBool(@"enableIMDBmeta", NO);
    bool showTitle = getPrefBool(@"showTitle", NO);
    
    rottenTomatoRatings rottenTomatoes;
    UIImage *tomato=nil;
    if(enableRottenTomatoes || enableRottenTomatoesAudience)
    {
        rottenTomatoes = getRottenTomatoesRating(title);
        if(rottenTomatoes.critic<=0.0) {
            enableRottenTomatoes=NO;
        }
        
        if(rottenTomatoes.audience<=0.0) {
            enableRottenTomatoesAudience=NO;
        }
        NSString *imagePath = [bundle pathForResource:@"tomato" ofType:@"png"];
        tomato = [UIImage imageWithContentsOfFile:imagePath];
    }
    
    imdbRatings imdb;
    UIImage *imdbPanel=nil;
    if(enableIMDBrating || enableIMDBmeta)
    {
        imdb = getImdbRating(title);
        
        if(imdb.imdbRating<=0.0) {
            enableIMDBrating=NO;
        }
        
        if(imdb.Metascore<=0.0) {
            enableIMDBmeta=NO;
        }
        NSString *imagePath = [bundle pathForResource:@"IMDB" ofType:@"png"];
        imdbPanel = [UIImage imageWithContentsOfFile:imagePath];
    }
    
    float textY=0;
    const float FRAME_W = 104;
    const float FRAME_H = 52;
    CGSize overlayFrameSize = CGSizeMake(FRAME_W>titleSize.width?FRAME_W:titleSize.width ,FRAME_H); 
    
    beginImageContext(overlayFrameSize);
    if(UIGraphicsGetCurrentContext()==nil)
        return nil;
    
    if(enableRottenTomatoes || enableRottenTomatoesAudience)
    {
        if(enableRottenTomatoes && enableRottenTomatoesAudience){
            rating = [NSString stringWithFormat:@"%.0f/%.0f", rottenTomatoes.critic, rottenTomatoes.audience];
        }
        else {
            if(enableRottenTomatoes) {
                rating = [NSString stringWithFormat:@"%.0f%%", rottenTomatoes.critic];
            }
            else {
                rating = [NSString stringWithFormat:@"%.0f%%", rottenTomatoes.audience];
            }
        }
        
        CGSize textSize = [rating sizeWithAttributes:@{NSFontAttributeName:font}];
        
        x+=padding;
        float y=0;
        [tomato drawAtPoint:CGPointMake(x,y)];
        
        
        textY=y+(tomato.size.height*2/3 - textSize.height/2);
        float textX = x + (tomato.size.width/2 - textSize.width/2);
        if(textX < 0)
            textX=0;
        
        [rating drawAtPoint:CGPointMake(textX, textY)
             withAttributes:@{NSFontAttributeName:font,
                              NSForegroundColorAttributeName:[UIColor whiteColor],
                              NSShadowAttributeName:shadow}];
        
        x+=tomato.size.width;
    }
    
    if(enableIMDBrating || enableIMDBmeta)
    {
        if(enableIMDBrating && enableIMDBmeta) {
            rating = [NSString stringWithFormat:@"%.1f/%.0f", imdb.imdbRating, imdb.Metascore];
        }
        else {
            if(enableIMDBrating) {
                rating = [NSString stringWithFormat:@"%.1f", imdb.imdbRating];
            }
            else {
                rating = [NSString stringWithFormat:@"%.0f%%", imdb.Metascore];
            }
        }
        
        CGSize textSize = [rating sizeWithAttributes:@{NSFontAttributeName:font}];
        
        x+=padding;
        float y;
        if(textY > 0.0){
            y = textY - margin;
        }
        else {
            y = overlayFrameSize.height/2 - imdbPanel.size.height/2;
            textY = y+margin;
        }
        
        [imdbPanel drawAtPoint:CGPointMake(x,y)];
        float textX = x + (imdbPanel.size.width/2 - textSize.width/2);
        if(textX < x)
            textX=x;
        
        
        shadow.shadowColor = [UIColor whiteColor];
        [rating drawAtPoint:CGPointMake(textX, textY)
             withAttributes:@{NSFontAttributeName:font,
                              NSForegroundColorAttributeName:[UIColor blackColor],
                              NSShadowAttributeName:shadow}];
    }
    
    
    if(showTitle) {
        shadow.shadowColor = [UIColor blackColor];
        [title drawAtPoint:CGPointMake(0,overlayFrameSize.height-titleSize.height)
            withAttributes:@{NSFontAttributeName:titleFont,
                             NSForegroundColorAttributeName:[UIColor whiteColor],
                             NSShadowAttributeName:shadow}];
    }
    
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    if(scaleDown) {
        overlayImage = scaleImage(overlayImage, 0.65);
    }
    
    [overlayImages setValue:overlayImage forKey:title];
    
    return overlayImage;
}

static UIImage* getOverlayItem(NSString *title, bool scaleDown)
{
    UIImage *overlayImage=[overlayImages objectForKey:title];
    if(overlayImage==nil) {
        overlayImage=generateOverlay(title, scaleDown);
    }
    return overlayImage;
}

#include <logos/logos.h>
#include <substrate.h>
@class VideosArtworkCell; 
static void (*_logos_orig$_ungrouped$VideosArtworkCell$setTitle$)(VideosArtworkCell*, SEL, NSString* ); static void _logos_method$_ungrouped$VideosArtworkCell$setTitle$(VideosArtworkCell*, SEL, NSString* ); 

#line 338 "/Users/john/Documents/RottenRatings/RottenRatings/RottenRatings.xm"

static void _logos_method$_ungrouped$VideosArtworkCell$setTitle$(VideosArtworkCell* self, SEL _cmd, NSString*  title) {
    _logos_orig$_ungrouped$VideosArtworkCell$setTitle$(self, _cmd, title);
    
    if(overlayImages==nil)
        overlayImages=[[NSMutableDictionary alloc] init];
        
        loadPreferences();
        if(!getPrefBool(@"enableSwitch", YES))
            return;
    
    UIImageView *ImageView = self.artworkView;
    if(ImageView==nil)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        const int TAG =0x8284; 
        UIImageView *overlay=(UIImageView *)[ImageView viewWithTag:TAG];
        UIImage *overlayImage=getOverlayItem(title,ImageView.frame.size.width<150.0);
        
        if(overlay!=nil && overlayImage!=nil) {
            if(overlay.image==overlayImage){
                return; 
            }
            else
            {
                
                overlay.image=overlayImage;
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            
            if([title isEqualToString:[self title]])
            {
                UIImageView *overlay=(UIImageView *)[ImageView viewWithTag:TAG];
                if(overlay==nil){
                    overlay = [[[UIImageView alloc] initWithImage:overlayImage] autorelease];
                    overlay.tag = TAG;
                    overlay.frame = CGRectMake(0,ImageView.frame.size.height-overlayImage.size.height,
                                               overlayImage.size.width, overlayImage.size.height);
                    overlay.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
                    
                    UIGraphicsEndImageContext();
                    
                    [ImageView addSubview:overlay];
                }
                else {
                    overlay.image=overlayImage;
                }
            }
        });
    });
}

































































static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$VideosArtworkCell = objc_getClass("VideosArtworkCell"); MSHookMessageEx(_logos_class$_ungrouped$VideosArtworkCell, @selector(setTitle:), (IMP)&_logos_method$_ungrouped$VideosArtworkCell$setTitle$, (IMP*)&_logos_orig$_ungrouped$VideosArtworkCell$setTitle$);} }
#line 461 "/Users/john/Documents/RottenRatings/RottenRatings/RottenRatings.xm"
