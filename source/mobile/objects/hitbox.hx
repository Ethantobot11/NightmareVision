package mobile.objects;

typedef hitbox = {
    var x:Float;
    var y:Float;
    var width:Float;
    var height:Float;
};


class Hitbox {
    public var x:Float;
    public var y:Float;
    public var width:Float;
    public var height:Float;

    public function new(?mode:String, ?libraryCreation:Bool = true)
    {
        if (libraryCreation)
            this.createHitboxFromLibrary(mode);
    }
    
    private function createHitboxFromLibrary(mode:String):Void
    {
        var Custom:String = mode != null ? mode : Options.hitboxMode;
        if (!MobileConfig.hitboxModes.exists(Custom))
            throw 'The ${Custom} Hitbox File doesn\'t exists.';

        var hitboxData = MobileConfig.hitboxModes.get(Custom).hitbox;
        if (hitboxData == null)
            throw 'The ${Custom} Hitbox File doesn\'t have a hitbox data.';

        x = hitboxData.x;
        y = hitboxData.y;
        width = hitboxData.width;
        height = hitboxData.height;
    }
}