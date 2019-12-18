class MoviesController < ApplicationController
  before_action :require_movie, only: [:show]

  def index
    if params[:query]
      data = MovieWrapper.search(params[:query])
    else
      data = Movie.all
    end

    render status: :ok, json: data
  end

  def show
    @movie = Movie.find_by(params[:title])

    if @movie
      render(
        status: :ok,
        json: @movie.as_json(
          only: [:title, :overview, :release_date, :inventory],
          methods: [:available_inventory],
        ),
      )
    else
      external_movie = MovieWrapper.search(params[:title])
      if external_movie.nil?
        render status: :not_found, json: { errors: { title: "Title not found" } }
      else
        render(
          status: :ok,
          json: external_movie.as_json(
            only: [:title, :overview, :release_date],
          ),
        )
      end
    end
  end

  def create
    movie = Movie.new(movie_params)

    if movie.save
      render(
        status: ok,
        json: movie.as_json(
          only: [:id, :title],
        ),
      )
    else
      render_error(:bad_request, movie.errors.messages)
    end
  end

  private

  def movie_params
    params.permit(:title, :overview, :release_date, :image_url, :external_id)
  end

  def require_movie
    @movie = Movie.find_by(title: params[:title])
    unless @movie
      render status: :not_found, json: { errors: { title: ["No movie with title #{params["title"]}"] } }
    end
  end
end
