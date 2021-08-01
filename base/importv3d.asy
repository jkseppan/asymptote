// module importv3d;
// Supakorn "Jamie" Rassameemasuang <rassamee@ualberta.ca>

import three;

struct v3dtypes
{
  int other=0;
  int material_=1;
  int transform_=2;
  int element=3;
  int centers=4;

  int line=64;
  int triangle=65;
  int quad=66;
  int curve=128;

  int bezierTriangle=129;
  int bezierPatch=130;

  int lineColor=192;
  int triangleColor=193;
  int quadColor=194;

  int curveColor=256;
  int bezierTriangleColor=257;
  int bezierPatchColor=258;

  int triangles=512; // specify nP;nN;nC

  //primitives
  int disk=1024;
  int cylinder=1025;
  int tube=1026;
  int sphere=1027;
  int halfSphere=1028;

  int animation=2048;
};
v3dtypes v3dtype;

struct v3dPatchData
{
    patch p;
    int matId;
    int centerIdx;
}

struct v3dSurfaceData
{
    bool hasCenter;
    triple center;
    material m;
    surface s;
}

struct v3dfile
{
    file _xdrfile;
    int fileversion;
    surface[][] surf=new surface[][];

    material[] materials=new material[];
    triple[] centers;
    bool processed=false;

    void operator init(string name)
    {
        _xdrfile=input(name, mode="xdr");
        fileversion=_xdrfile;
    }

    int getType()
    {
        return _xdrfile;
    }

    material readMaterial()
    {
        _xdrfile.dimension(4);
        _xdrfile.singlereal(true);

        pen diffusePen=rgba(_xdrfile);
        pen emissivePen=rgba(_xdrfile);
        pen specularPen=rgba(_xdrfile);
        real[] params=_xdrfile;

        _xdrfile.singlereal(false);

        real shininess=params[0];
        real metallic=params[1];
        real F0=params[2];

        return material(diffusePen,emissivePen,specularPen,1.0,shininess,metallic,F0);
    }

    pen[] readColorData(int size=4)
    {
        _xdrfile.singlereal(false);
        _xdrfile.dimension(4);
        pen[] newPen=new pen[size];
        for (int i=0;i<size;++i)
        {
            newPen[i]=rgba(_xdrfile);
        }
        return newPen;
    }

    triple[][] readRawPatchData()
    {
        triple[][] val=new triple[4][4];
        _xdrfile.singlereal(false);
        _xdrfile.dimension(4,4);
        val=_xdrfile;
        return val;
    }

    triple[][] readRawTriangleData()
    {
        triple[][] val=new triple[][];
        _xdrfile.singlereal(false);
        _xdrfile.dimension(1);

        for (int i=0;i<4;++i)
        {
            triple subval[] = new triple[i+1];
            for (int j=0;j<=i;++j)
            {
                subval[j]=_xdrfile;
            }
            val.push(subval);
        }
        return val;
    }

    v3dPatchData readBezierPatch()
    {
        triple[][] val=readRawPatchData();
        _xdrfile.singlereal(false);
        _xdrfile.dimension(1);
        int centerIdx=_xdrfile;
        int matIdx=_xdrfile;

        v3dPatchData vpd;
        vpd.p=patch(val);
        vpd.matId=matIdx;
        vpd.centerIdx=centerIdx;
        return vpd;
    }

    v3dPatchData readBezierTriangle()
    {
        triple[][] val=readRawTriangleData();
        int centerIdx=_xdrfile;
        int matIdx=_xdrfile;

        v3dPatchData vpd;
        vpd.p=patch(val,triangular=true);
        vpd.matId=matIdx;
        vpd.centerIdx=centerIdx;
        return vpd;
    }

    triple[] readCenters()
    {
        _xdrfile.singlereal(false);
        _xdrfile.dimension(1);
        int centerCount=_xdrfile;

        _xdrfile.dimension(centerCount);
        triple[] centersFetched=new triple[centerCount];
        if (centerCount>0)
            centersFetched=_xdrfile;
        return centersFetched;
    }

    v3dPatchData readBezierPatchColor()
    {
        triple[][] val=readRawPatchData();
        int centerIdx=_xdrfile;
        int matIdx=_xdrfile;
        pen[] colData=readColorData(4);

        v3dPatchData vpd;
        vpd.p=patch(val,colors=colData);
        vpd.matId=matIdx;
        vpd.centerIdx=centerIdx;
        return vpd;
    }

    v3dPatchData readBezierTriangleColor()
    {
        triple[][] val=readRawTriangleData();
        int centerIdx=_xdrfile;
        int matIdx=_xdrfile;
        pen[] colData=readColorData(3);


        v3dPatchData vpd;
        vpd.p=patch(val,triangular=true,colors=colData);
        vpd.matId=matIdx;
        vpd.centerIdx=centerIdx;
        return vpd;
    }

    void addToSurfaceData(v3dPatchData vp)
    {
        if (!surf.initialized(vp.centerIdx))
        {
            surf[vp.centerIdx]=new surface[];
        }
        if (!surf[vp.centerIdx].initialized(vp.matId))
        {
            surface s;
            surf[vp.centerIdx][vp.matId]=s;
        }
        surf[vp.centerIdx][vp.matId].push(vp.p);
    }

    surface[][] process()
    {
        if (processed)
        {
            return surf;
        }

        while (!eof(_xdrfile))
        {
            int ty=getType();
            if (ty == v3dtype.material_)
            {
                materials.push(this.readMaterial());
            }
            else if (ty == v3dtype.bezierPatch)
            {
                addToSurfaceData(this.readBezierPatch());
            }
            else if (ty == v3dtype.bezierTriangle)
            {
                addToSurfaceData(this.readBezierTriangle());
            }
            else if (ty == v3dtype.bezierPatchColor)
            {
                addToSurfaceData(this.readBezierPatchColor());
            }
            else if (ty == v3dtype.bezierTriangleColor)
            {
                addToSurfaceData(this.readBezierTriangleColor());
            }
            else if (ty == v3dtype.centers)
            {
                centers=this.readCenters();
            }
            else
            {
                write('Unknown Type.');
            }
        }

        processed=true;
        return surf;
    }

    v3dSurfaceData[] generateSurfaceList()
    {
        if (!processed)
        {
            process();
        }

        v3dSurfaceData[] vsdFinal;
        for (int i=0;i<surf.length;++i)
        {
            if (surf.initialized(i))
            {
                for (int j=0;j<surf[i].length;++j)
                {
                    if (surf[i].initialized(j))
                    {
                        v3dSurfaceData vsd;
                        vsd.s=surf[i][j];
                        vsd.m=materials[j];
                        if (j==0)
                        {
                            vsd.hasCenter=false;
                        }
                        else
                        {
                            vsd.hasCenter=true;
                            vsd.center=centers[i-1];
                        }
                        vsdFinal.push(vsd);
                    }
                }
            }
        }
        return vsdFinal;
    }
};

void _test_fn_importv3d()
{
    v3dfile xf=v3dfile("colorpatch.v3d");
    v3dSurfaceData[] vsd=xf.generateSurfaceList();
    for (v3dSurfaceData vs : vsd)
    {
        draw(vs.s,vs.m);
    }
}
_test_fn_importv3d();