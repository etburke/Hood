//
//  GridView.m
//
//

#import <OpenGLES/ES1/gl.h>
#import "GridView.h"
#import "ElevationGrid.h"

static GLfloat texCoords[ELEVATION_PATH_SAMPLES_INT*ELEVATION_PATH_SAMPLES_INT*2];


@implementation GridView

- (void) dealloc
{
    [gridTexture release];
    [super dealloc];
}

- (void) buildView 
{
    NSLog(@"[GV] buildView");    
    
    gridTexture = [Texture newTextureFromImage:[UIImage imageNamed:@"PortlandMap.png"].CGImage];
    

    // Populate texture coordinates.
    
    GLfloat texCoordSpacing = 1.0 / ELEVATION_PATH_SAMPLES;
    
    int index = 0;
    
    for (int row=0; row < ELEVATION_PATH_SAMPLES; row++)
    {
        for (int column=0; column < ELEVATION_PATH_SAMPLES; column++)
        {
            GLfloat u = column * texCoordSpacing;
            GLfloat v = row * texCoordSpacing;
            
            texCoords[index] = u;
            index++;
            texCoords[index] = v;
            index++;
        }
    }
    
    
}

- (void) drawFog
{
    GLfloat fogColor[4] = {0.6f, 0.0f, 0.9f, 0.7f};
    glFogfv(GL_FOG_COLOR, fogColor);
    
    glFogf(GL_FOG_MODE, GL_LINEAR);
    glFogf(GL_FOG_DENSITY, 1.0);
    
    glFogf(GL_FOG_START, 0.0);
    
    CGFloat fogEnd = GRID_SCALE_HORIZONTAL * ELEVATION_LINE_LENGTH_HIGH;
    glFogf(GL_FOG_END, fogEnd);
    
    glHint(GL_FOG_HINT, GL_NICEST);
    
    glEnable(GL_FOG);
}

- (void) drawGrid
{
    ushort lineIndex [1024];
    
    Coord3D *verts = &worldCoordinateDataHigh[0][0];
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
	
	bool fill = true;
	
	if (fill)
		glColor4f(0,0,1,1);
	else	
		glColorMask(0,0,0,0);			// Turn of visible filling.
    
    for (int y=0; y < gridSize-1; y++)
    {
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
    
    // draw horizontal lines.
    
	glColorMask(1,1,1,1);
    glColor4f(1,1,0,1);
	
    
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
}

- (void) drawTexturedGrid
{
    /*
	glBindTexture(GL_TEXTURE_2D, gridTexture.handle);
    
    // Render to opengl.
    
    glColor4f(1,1,1,1);
	glDisable(GL_LIGHTING);
    
	glDisable(GL_BLEND);
    
	glEnable(GL_DEPTH_TEST);
    
    glEnable(GL_CULL_FACE);
    
	glEnableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);

    ///////
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    ///////
    
	glVertexPointer(3, GL_FLOAT, 24, &ndl->vertex[0].x);
    
    if (ndl->textureChannelCount)
        glTexCoordPointer(ndl->textureChannelCount, GL_FLOAT, 0, ndl->textureChannel);
    
    for (int i=0; i < ndl->polygonCount; i++)
    {
        GLsizei elemCount = ndl->polygon[i].vertexCount;
        glDrawElements(GL_TRIANGLE_FAN, elemCount, GL_UNSIGNED_SHORT, ndl->polygon[i].vertexIndex);
    }

/////////////////    
    for (int y=0; y < gridSize-1; y++)
    {
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
/////////////////    
    */
    
    ////
    // From stackoverflow
    ////
//    glVertexPointer(3, GL_FLOAT, sizeof(TexturedVertexData3D), &vertices[0]);
//    glTexCoordPointer(2, GL_FLOAT, sizeof(TexturedVertexData3D), &vertices[0].texCoords);
//    glDrawArrays(GL_TRIANGLES, 0, nVertices);    
}

- (void) drawInGLContext 
{
    [self drawGrid];
    [self drawFog];

//    [self drawTexturedGrid];
}

@end
