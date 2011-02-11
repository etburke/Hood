//
//  ObjGridView.m
//
//

#import <OpenGLES/ES1/gl.h>
#import "ObjGridView.h"

@implementation ObjGridView

- (void) buildView 
{
    self.hidden = NO;    
    self.zrot = 0.0;    
    self.sizeScalar = 100.0;

	self.frame = CGRectZero;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"arc" ofType:@"obj"];
    
    self.geometry = [[Geometry newOBJFromResource:path] autorelease];
    self.geometry.cullFace = NO;
    
    self.color = [UIColor greenColor];
    
}

- (void) displayGeometry 
{
    if (texture == nil && [textureName length] > 0) 
    {
        NSLog(@"Loading texture named %@", textureName);
        NSString *textureExtension = [[textureName componentsSeparatedByString:@"."] objectAtIndex:1];
        NSString *textureBaseName = [textureName stringByDeletingPathExtension];
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:textureBaseName ofType:textureExtension];
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:imagePath]; 
        UIImage *textureImage =  [[UIImage alloc] initWithData:imageData];
        CGImageRef cgi = textureImage.CGImage;

        self.texture = [[Texture newTextureFromImage:cgi] autorelease];           
        
        [imageData release];
        [textureImage release];
    }

    glScalef(-sizeScalar, sizeScalar, 20.0);
    
    if (texture)
    {
        [Geometry displaySphereWithTexture:self.texture];
    }
	else
    {
        // Shaded
        
        //[self.geometry displayShaded:self.color];
        
        
        // Wireframe
        
        [self.geometry displayWireframe];
        
    }
}

@end
