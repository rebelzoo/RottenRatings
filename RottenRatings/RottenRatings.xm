#define kBundlePath @"/Library/MobileSubstrate/DynamicLibraries/RottenRatings.bundle"
#include <Videos/VideosArtworkCell.h>
#include <UIKit/UIKit.h>

#define PreferencesFilePath [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.christmanzoo.RottenRatings.plist"]

static NSDictionary *prefsDict = nil;

static void loadPreferences() {
    if(prefsDict==nil)
    {
        prefsDict = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
        //NSLog(@"%@", PreferencesFilePath);
        //NSLog(@"prefs: %@", prefsDict);
    }
}
static void preferenceChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo ) {
    if(prefsDict!=nil)
    {
        [prefsDict release];
        prefsDict=nil;
    }
    loadPreferences();
}

static NSData* getDataFromURL(NSString *URL)
{
    //NSLog(@"%@", URL);
    
    int tries = 0;
    NSData* data = nil;
    while(data==nil && tries < 20)
    {
        data = [NSData dataWithContentsOfURL:[NSURL URLWithString:URL]];
        tries++;
    }
    
    return data;
}

struct rottenTomatoRatings
{
    NSNumber* critic;
    NSNumber* audience;
};

static rottenTomatoRatings getRottenTomatoesRating(NSString *title)
{
    NSString *query = [title stringByReplacingOccurrencesOfString: @" " withString:@"+"];
    NSString *URL = @"http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=42z34f7h6erk6de8mmbsrten&page_limit=1&q=";
    URL = [URL stringByAppendingString:query];
    
    //NSNumber *critic = [NSNumber numberWithInt:-1];
    rottenTomatoRatings rtRatings;
    
    NSData *data = getDataFromURL(URL);
    if(data != nil)
    {
        NSError *e = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error:&e];
        //NSLog(@"%@", json);
        
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
            //NSLog(@"%@", json);
            NSDictionary *ratings = (NSDictionary *)[json objectForKey:@"ratings"];
            //NSLog(@"%@", ratings);
            if(ratings != nil)
            {
                //NSLog(@"%@", ratings);
                rtRatings.critic = [ratings objectForKey:@"critics_score"];
                rtRatings.audience = [ratings objectForKey:@"audience_score"];
            }
        }
    }
    
    return rtRatings;
}

struct imdbRatings
{
    NSNumber* Metascore;
    NSNumber* imdbRating;
};

static imdbRatings getImdbRating(NSString *title)
{
    NSString *query = [title stringByReplacingOccurrencesOfString: @" " withString:@"+"];
    NSString *URL = @"http://www.omdbapi.com/?i=&t=";
    URL = [URL stringByAppendingString:query];
    
    //NSNumber *critic = [NSNumber numberWithInt:-1];
    imdbRatings ratings;
    
    NSData *data = getDataFromURL(URL);
    if(data != nil)
    {
        NSError *e = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error:&e];
        NSLog(@"%@", json);
        
        if(json != nil)
        {
            ratings.Metascore = [json objectForKey:@"Metascore"];
            ratings.imdbRating = [json objectForKey:@"imdbRating"];
            //NSLog(@"%@", critic);
        }
    }
    
    return ratings;
}


%hook VideosArtworkCell
- (void)setTitle:(NSString* )title {
    //%log;
    %orig;
    
    loadPreferences();
    if(![[prefsDict objectForKey:@"enableSwitch"] boolValue])
        return;
    
    UIImageView* ImageView = self.artworkView;
    if(ImageView==nil)
        return;
    
    UIImage* img = ImageView.image;
    UIGraphicsBeginImageContext(img.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if(context!=nil && img!=nil)
    {
        const int margin = 4;
        const int padding = 2;
        float x=margin;
        
        bool enableRottenTomatoes = [[prefsDict objectForKey:@"enableRottenTomatoes"] boolValue];
        bool enableRottenTomatoesAudience = [[prefsDict objectForKey:@"enableRottenTomatoesAudience"] boolValue];
        bool enableIMDBrating = [[prefsDict objectForKey:@"enableIMDBrating"] boolValue];
        bool enableIMDBmeta = [[prefsDict objectForKey:@"enableIMDBmeta"] boolValue];

        UIFont *font = [UIFont fontWithName:@"Arial" size:16];
        [img drawInRect:CGRectMake(0.0,0.0,img.size.width, img.size.height)];
        NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
        NSString *rating=nil;

        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        shadow.shadowColor = [UIColor blackColor];
        shadow.shadowBlurRadius = 2.0;
        shadow.shadowOffset = CGSizeMake(0.0,1.0);
        
        rottenTomatoRatings rottenTomatoes;
        if(enableRottenTomatoes || enableRottenTomatoesAudience)
        {
            rottenTomatoes = getRottenTomatoesRating(title);
            if(rottenTomatoes.critic==nil) {
                enableRottenTomatoes=NO;
            }

            if(rottenTomatoes.audience==nil) {
                enableRottenTomatoesAudience=NO;
            }
        }
        
        if(enableRottenTomatoes || enableRottenTomatoesAudience)
        {
            if(enableRottenTomatoes && enableRottenTomatoesAudience){
                rating = [NSString stringWithFormat:@"%@/%@", rottenTomatoes.critic, rottenTomatoes.audience];
            }
            else { if(enableRottenTomatoes) {
                rating = [NSString stringWithFormat:@"%@%%", rottenTomatoes.critic];
            }
            else {
                rating = [NSString stringWithFormat:@"%@%%", rottenTomatoes.critic];
            }}
                
            CGSize textSize = [rating sizeWithAttributes:@{NSFontAttributeName:font}];
    
            NSString *imagePath = [bundle pathForResource:@"tomato" ofType:@"png"];
            UIImage *tomato = [UIImage imageWithContentsOfFile:imagePath];
                    
            float y=img.size.height-tomato.size.height-margin;
            [tomato drawAtPoint:CGPointMake(margin,y)];
                     
            //Rating Text
            x+=padding;
            y=img.size.height - tomato.size.height/2 - textSize.height/2;
            
            float textX = x + (tomato.size.width/2 - textSize.width/2);
            if(textX < 0)
                textX=0;
            
            [rating drawAtPoint:CGPointMake(textX, y)
                 withAttributes:@{NSFontAttributeName:font,
                                  NSForegroundColorAttributeName:[UIColor whiteColor],
                                  NSShadowAttributeName:shadow}];
            
            x+=tomato.size.width;
        }

        imdbRatings imdb;
        if(enableIMDBrating || enableIMDBmeta)
        {
            imdb = getImdbRating(title);
            
            NSLog(@"%@ %@", imdb.imdbRating, imdb.Metascore);
            
            if(imdb.imdbRating==nil) {
                enableIMDBrating=NO;
            }
            
            if(imdb.Metascore==nil) {
                enableIMDBmeta=NO;
            }

        }
        
        if(enableIMDBrating || enableIMDBmeta)
        {
            if(enableIMDBrating && enableIMDBmeta) {
                rating = [NSString stringWithFormat:@"%@/%@", imdb.imdbRating, imdb.Metascore];
            }
            else { if(enableIMDBrating) {
                    rating = [NSString stringWithFormat:@"%@", imdb.imdbRating];
            }
            else {
                rating = [NSString stringWithFormat:@"%@%%", imdb.Metascore];
            }}
                
            CGSize textSize = [rating sizeWithAttributes:@{NSFontAttributeName:font}];
                    
            float y=img.size.height-textSize.height-12;
            CGRect rect = CGRectMake(x,y,textSize.width+8,textSize.height+8);
            [[UIColor yellowColor] setFill];
            CGContextSetAlpha(context,0.95);
            [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:8.0] fill];
            CGContextSetAlpha(context,1.0);
            
            //Rating Text
            shadow.shadowColor = [UIColor whiteColor];
            [rating drawAtPoint:CGPointMake(x+4, y+4)
                 withAttributes:@{NSFontAttributeName:font,
                                  NSForegroundColorAttributeName:[UIColor blackColor],
                                  NSShadowAttributeName:shadow}];
        }
        
        ImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    }
}
%end
