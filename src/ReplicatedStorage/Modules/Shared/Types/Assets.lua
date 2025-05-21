export type List<T> = {[number]: T}
export type GenericFolderContainer<T> = Folder & {
    [string]: GenericFolderContainer<T> & T,
}

export type FrameButtonStructure = Frame & {
    Button: TextButton,
    Btn: TextButton,
    UIScale: UIScale,
    UIStroke: UIStroke,

    Key: Frame & {KeyBind: TextLabel},
    Icon: ImageLabel,
    Cooldown: CanvasGroup & {Fill: Frame},
}

return {}