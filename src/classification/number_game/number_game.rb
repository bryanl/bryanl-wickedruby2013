require 'rubygems'
require 'zlib'
require 'matrix'
require 'chunky_png'
require 'libsvm'
require 'sinatra'

get '/' do
  game = NumberGame.new
  erb :index, locals: { game: game }
end

get '/:index.png' do
  content_type 'image/png'
  game = NumberGame.new
  game.png(params[:index]).to_blob
end

class Dataset < Struct.new(:images, :labels)
end

class Loader
  def initialize(image_file, label_file)
    @image_file = image_file
    @label_file = label_file
  end

  def dataset
    Dataset.new load_images(@image_file), load_labels(@label_file)
  end

  def load_images(file)
    images = []  
    Zlib::GzipReader.open(file) do |f|
      magic, image_count = f.read(8).unpack('N2')
      puts "image count: #{image_count}"
      raise "#{@image_file} is not an image file (#{magic})" if magic != 0x803
      row_count, col_count = f.read(8).unpack('N2')
      puts "#{row_count}x#{col_count}"
      image_count.times do
        images << f.read(row_count * col_count)
      end
    end
    images
  end

  def load_labels(file)
    labels = []
    Zlib::GzipReader.open(file) do |f|      
      magic, label_count = f.read(8).unpack('N2')
      puts "label count: #{label_count}"
      raise "#{@label_file} is not a label file (#{magic})" if magic != 0x801
      labels = f.read(label_count).unpack('C*')
    end
    labels
  end
end

class NumberGame
  attr_reader :test_loader, :model

  def initialize
    # Yeah, you'll probably want to change this
    data_dir = '/Users/bryan/Development/talks/wicked2013/data'
    test_images, test_labels = ['t10k-images-idx3-ubyte.gz', 't10k-labels-idx1-ubyte.gz'].map do |f|
      File.join(data_dir, f)
    end

    @test_loader = Loader.new(test_images, test_labels)

    # and the path here too :)
    @model = Libsvm::Model.load("/Users/bryan/Development/talks/wicked2013/src/classification/images.model")
  end

  def image(index)
    my_image = @test_loader.dataset.images[index.to_i]
    my_image.unpack('C*')
  end

  def png(index)
    png = ChunkyPNG::Image.new(28, 28, ChunkyPNG::Color::BLACK)
    my_image = image(index)

    (0..27).each do |y|
      (0..27).each do |x|
        pixel = my_image[y*28+x]
        png[x,y] = ChunkyPNG::Color.grayscale(pixel)
      end
    end

    png
  end

  def label(index)
    @test_loader.dataset.labels[index].to_i
  end

  def predict(index)
    model.predict(Libsvm::Node.features(*image(index.to_i))).to_i
  end 
end
