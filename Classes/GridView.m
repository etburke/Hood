//
//  GridView.m
//
//

#import <OpenGLES/ES1/gl.h>
#import "GridView.h"
//#import "ElevationGrid.h"
#import "HoodGrid.h"


@implementation GridView

+ (CGFloat) randomColor
{
    return random() / (CGFloat)RAND_MAX;
}


- (void) buildView 
{
    NSLog(@"[GV] buildView");    
    
    redColor = [GridView randomColor];
    greenColor = [GridView randomColor];
    blueColor = [GridView randomColor];
    
}

#define MAX_LINE_LENGTH 256

- (void) drawFog
{
    GLfloat fogColor[4] = {0.6f, 0.0f, 0.9f, 0.7f};
    glFogfv(GL_FOG_COLOR, fogColor);

    glFogf(GL_FOG_MODE, GL_LINEAR);
    glFogf(GL_FOG_DENSITY, 1.0);

    glFogf(GL_FOG_START, 0.0);
    
    CGFloat fogEnd = GRID_SCALE_HORIZONTAL * ELEVATION_LINE_LENGTH_LOW;
    glFogf(GL_FOG_END, fogEnd);

    glHint(GL_FOG_HINT, GL_NICEST);

    glEnable(GL_FOG);
}


- (void) drawGrid
{
    ushort lineIndex [1024];
    
    Coord3D *verts = &worldCoordinateDataLow[0][0];
    int gridSize = ELEVATION_PATH_SAMPLES;
    
    glDisable(GL_LIGHTING);
    
	glPolygonOffset(1,1);			// Offset fill in z-buffer.
	glEnable(GL_POLYGON_OFFSET_FILL);
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
	glVertexPointer(3, GL_FLOAT, 0, verts);
    
    glLineWidth(1.0);
    
    glScalef(GRID_SCALE_HORIZONTAL, GRID_SCALE_HORIZONTAL, GRID_SCALE_VERTICAL);
    
    // fill horizontal strip of triangles.
	
	glEnable(GL_DEPTH_TEST);

	
#if 0
	BOOL fill = YES;
	BOOL alt = YES;
	
    
	
    for (int y=0; y < gridSize-1; y++)
    {
        if (fill)
        {
            alt = !alt;

//            glColorMask(1, 1, 1, 1);
            
            if (alt)
                glColor4f(0, 0.66, 1, 1);
            else
                glColor4f(0, 0, 0.33, 1);
        }
        else	
        {
            glColor4f(0, 0, 1, 1);
//            glColorMask(0,0,0,0);			// Turn off visible filling.
        }

    	int start1 = y * gridSize;
        int start2 = start1 + gridSize;
		
        // build index array.
        
		int ct = 0;
		
        for (int x=0; x < gridSize; x++)
		{
        	lineIndex[ct++] = start1 + x;
			lineIndex[ct++] = start2 + x;
		}
		
		glDrawElements(GL_TRIANGLE_STRIP, ct, GL_UNSIGNED_SHORT, lineIndex);
    }
	
#else
    glColorMask(1,1,1,1);
    glColor4f(1,1,0, 0.3);
    
    
    for (int y=0; y < gridSize; y++)
    {
        int start = y * gridSize;
        
        // build index array.
        
        for (int x=0; x < gridSize; x++)
            lineIndex[x] = start + x;
            
        glDrawElements(GL_LINE_STRIP, gridSize, GL_UNSIGNED_SHORT, lineIndex);
    }
    
    // draw horizontal lines.
    
    for (int x=0; x < gridSize; x++)
    {
        int start = x;
        
        // build index array.
        
        for (int y=0; y < gridSize; y++)
            lineIndex[y] = start + (y * gridSize);
            
        glDrawElements(GL_LINE_STRIP, gridSize, GL_UNSIGNED_SHORT, lineIndex);
    }
#endif
}

- (void) drawInGLContext 
{
    [self drawGrid];
//    [self drawFog];
}

@end

