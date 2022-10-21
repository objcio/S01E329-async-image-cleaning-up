import SwiftUI

@MainActor
final class ImageLoader: ObservableObject {
    @Published private var _image: Image?
    @Published var url: URL

    var image: Image? {
        guard _image == nil else { return _image }
        loadFromCache()
        return _image
    }

    init(url: URL) {
        self.url = url
    }

    func loadFromCache() {
        if let resp = URLSession.shared.configuration.urlCache?.cachedResponse(for: .init(url: url)) {
            guard let nsImage = NSImage(data: resp.data) else { return }
            _image = Image(nsImage: nsImage)
        }
    }

    func load() async {
        _image = nil
        do {
//            try await Task.sleep(nanoseconds: NSEC_PER_SEC*3)
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let nsImage = NSImage(data: data) else { return }
            _image = Image(nsImage: nsImage)
        } catch {
            print(error)
        }
    }

}

struct MyAsyncImage<Placeholder: View>: View {
    var url: URL
    @ViewBuilder var placeholder: Placeholder
    private var _resizable = false
    @StateObject private var loader: ImageLoader

    init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder()
        self._loader = .init(wrappedValue: ImageLoader(url: url))
    }

    var body: some View {
        MyUnmanagedAsyncImage(url: url, loader: loader, resizable: _resizable, placeholder: { placeholder })
    }

    func resizable() -> Self {
        var copy = self
        copy._resizable = true
        return copy
    }
}

struct MyUnmanagedAsyncImage<Placeholder: View>: View {
    init(url: URL, loader: ImageLoader, resizable: Bool = false, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder()
        self.loader = loader
        self._resizable = resizable
    }

    var url: URL
    @ViewBuilder var placeholder: Placeholder
    private var _resizable = false
    @ObservedObject private var loader: ImageLoader

    var body: some View {
        ZStack {
            if let image = loader.image {
                if _resizable {
                    image.resizable()
                } else {
                    image
                }
            } else {
                let _ = print("Showing placeholder")
                placeholder

            }
        }
        .task(id: url) {
            loader.url = url
            await loader.load()
        }
    }

    func resizable() -> Self {
        var copy = self
        copy._resizable = true
        return copy
    }
}

var loaders: [URL: ImageLoader] = [:]

@MainActor
func loader(for url: URL) -> ImageLoader {
    if let l = loaders[url] {
        return l
    }
    let l = ImageLoader(url: url)
    loaders[url] = l
    return l
}

struct ChangeView: View {
    @State private var selectedURL = Photo.sample[0].urls.full

    var body: some View {
        HStack {
            VStack {
                ForEach(Photo.sample) { photo in
                    Text(photo.id)
                        .onTapGesture {
                            selectedURL = photo.urls.full
                        }
                }
            }
            MyAsyncImage(url: selectedURL, placeholder: { Color.pink })
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            GridView().tabItem { Text("Grid") }
            ChangeView().tabItem { Text("Change URL") }
        }
    }
}

@MainActor
struct GridView: View {
    @State var selectedPhoto: URL?

    func image(for url: URL) -> some View {
        MyAsyncImage(url: url, placeholder: {
            Color.red
        })
        .resizable()
        .aspectRatio(contentMode: .fit)
    }

    var body: some View {
        if let url = selectedPhoto {
            image(for: url)
            .onTapGesture {
                selectedPhoto = nil
            }
        } else {
            ScrollView {
                LazyVGrid(columns: [.init(.adaptive(minimum: 100))]) {
                    ForEach(Photo.sample) { photo in
                        let url = photo.urls.thumb
                        image(for: url)
                        .onTapGesture {
                            selectedPhoto = url
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
