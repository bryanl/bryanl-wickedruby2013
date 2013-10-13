#!/usr/bin/env ruby

require 'rubygems'
require 'zlib'
require 'matrix'
require 'chunky_png'
require 'libsvm'

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

data_dir = '/Users/bryan/Development/talks/wicked2013/data'
train_images, train_labels = ['train-images-idx3-ubyte.gz', 'train-labels-idx1-ubyte.gz'].map do |f|
  File.join(data_dir, f)
end

start_time = Time.now.to_f

loader = Loader.new(train_images, train_labels)
train_dataset = loader.dataset

load_time = Time.now.to_f - start_time

puts "load time: #{load_time}"

puts "training"

problem =Libsvm::Problem.new
parameter = Libsvm::SvmParameter.new

parameter.cache_size = 100
parameter.eps = 0.001
parameter.c = 10

sample_size = 5000

indices = sample_size.times.map{ Random.rand(train_dataset.images.size) }

selected_images = indices.map{|i| train_dataset.images[i]}
selected_labels = indices.map{|i| train_dataset.labels[i]}

examples = selected_images.map do |data|
  array = data.unpack('C*')
  vector = Vector.elements(array)
  Libsvm::Node.features(vector.normalize.to_a)
end

problem.set_examples(selected_labels, examples)
model = Libsvm::Model.train(problem, parameter)

train_time = Time.now.to_f - load_time
puts "train time: #{train_time}"

model.save("images.model")
save_time = Time.now.to_f - train_time

puts "save time: #{save_time}"

puts "predicting"

test_images, test_labels = ['t10k-images-idx3-ubyte.gz', 't10k-labels-idx1-ubyte.gz'].map do |f|
  File.join(data_dir, f)
end

test_loader = Loader.new(test_images, test_labels)
test_dataset = test_loader.dataset

test_sample_size = 5000
indices = test_sample_size.times.map{ Random.rand(test_dataset.images.size) }

selected_images = indices.map{|i| test_dataset.images[i]}
selected_labels = indices.map{|i| test_dataset.labels[i]}

predictions = selected_images.each_with_index.map do |image, i|
  pred = model.predict(Libsvm::Node.features(*image.unpack('C*')))
  pred == selected_labels[i]
end

correct = predictions.find_all{|p| p}.size

puts "prediction size: #{predictions.size}"
puts "correct guesses: #{correct}"
puts "grade = #{correct.to_f / predictions.size}"